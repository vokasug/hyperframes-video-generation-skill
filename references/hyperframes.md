# Контракт hyperframes (проверен реальным рендером)

hyperframes превращает HTML + GSAP в MP4: headless-Chrome ищет каждый кадр по времени,
FFmpeg кодирует. Правила ниже обязательны — собраны из боевых ошибок.

## Структура композиции

```html
<div id="root" data-composition-id="main" data-start="0"
     data-duration="126.34" data-width="1920" data-height="1080">
  <div id="bg" class="clip" data-start="0" data-duration="126.34" data-track-index="0">…</div>
  <section id="s1" class="clip scene" data-start="0" data-duration="9.65" data-track-index="11">…</section>
  <audio id="vo1" class="clip" data-start="0.25" data-duration="9.1" data-track-index="2" src="assets/vo/01.mp3"></audio>
  <audio id="bgm" class="clip" data-start="0" data-duration="126.34" data-track-index="3" data-volume="0.14" src="assets/bgm.mp3"></audio>
</div>
```

- На руте `data-duration` = полная длина видео — ОБЯЗАТЕЛЬНО (иначе длительность выводится
  из таймлайна и может схлопнуться).
- У каждого timed-элемента: `class="clip"` + `data-start` + `data-duration` + `data-track-index`.
- На одном треке клипы не пересекаются. Сцены клади на разные треки (10, 11, 12…), VO — на
  свой, музыку — на свой.
- **У `<audio>` обязателен уникальный `id`** — без него звука в рендере НЕ будет.
- Сцены: абсолютно спозиционированные `<section>` поверх друг друга (DOM-порядок = z-порядок).

## GSAP-контракт

```html
<script src="assets/gsap.min.js"></script>  <!-- локально, не CDN! -->
<script>
  const tl = gsap.timeline({ paused: true });
  // ... твины с абсолютными позициями (3-й аргумент, секунды)
  tl.set({}, {}, 126.34);                      // растянуть таймлайн до конца
  window.__timelines = window.__timelines || {};
  window.__timelines["main"] = tl;             // ключ = data-composition-id
</script>
```

1. Таймлайн только `{ paused: true }`, регистрация на `window.__timelines[id]`.
2. Анимируй только: `opacity, x, y, scale, scaleX/Y, rotation, color, backgroundColor,
   borderColor, strokeDashoffset, attr (SVG)`. НИКОГДА: `width, height, top, left, visibility`.
3. Позиция — 3-й аргумент в секундах, из timeline.json. `gsap.defaults({ ease: "power3.out" })`.
4. **Hard-kill после каждого exit-твина сцены:**
   `tl.to("#s1 .scene-fade", {opacity:0, ...}, 9.25); tl.set("#s1 .scene-fade", {opacity:0}, 9.65);`
   — иначе check ругается (gsap_exit_missing_hard_kill) и возможны «застрявшие» кадры.
5. **Не смешивай CSS-transform и GSAP на одном элементе** (gsap_css_transform_conflict):
   убери transform из CSS, используй `tl.fromTo`.
6. Скрытие «до появления» — только через `fromTo` (immediateRender прячет сразу).
   Элемент, видимый с начала сцены, не анимируй на появление позже его метки.
7. Бесконечные циклы: `repeat: <конечное N>` (посчитай N до конца видео), не `repeat: -1` —
   таймлайн уходит в Infinity. N считай от ОСТАВШЕГОСЯ времени, а не от TOTAL:
   `repeat = Math.ceil((TOTAL - t0) / d) - 1`, где t0 — старт твина, d — длительность цикла
   (для yoyo полный цикл = 2d... точнее: покрытие = d*(repeat+1)). Repeat от TOTAL при t0>0
   удлиняет таймлайн за конец видео: элемент анимируется «в никуда», а snapshot-тула
   рисует кадры за пределами длительности (артефакт «кадр на 348с»).
8. Счётчики: `tl.to(obj, {v: N, onUpdate: () => el.textContent = fmt(obj.v)})` — onUpdate
   отрабатывает и при seek, детерминировано.
9. SVG-рисование линий: `stroke-dasharray` в CSS, твин `strokeDashoffset` → 0.
10. Повторяющиеся структуры (узлы, пузыри) генерируй JS-циклом с ФИКСИРОВАННЫМИ координатами
    (без Math.random — детерминизм).
11. Градиентный текст из спанов-слов (`background-clip:text`): градиент вешай на САМИ спаны
    (`.title .w { background: linear-gradient(...); -webkit-background-clip: text;
    background-clip: text; color: transparent; -webkit-text-fill-color: transparent }`),
    а не на родителя — у спанов прозрачный fill без своего background, check ловит
    `text_not_painted`.
12. Крупные однострочники (числа с валютой, слэм-заголовки): `white-space: nowrap` + явный
    `left`/`width`. Абсолютно позиционированный текст без width получает shrink-to-fit и
    переносится в самом неожиданном месте («100 000 ₽» рвётся по узкому nbsp).
13. Детей панели/полосы клади ВНУТРЬ её позиционированного контейнера. Дети полноэкранного
    клипа с `top:` позиционируются от верха кадра — нижняя панель «уезжает» наверх.

## Шрифты

`scripts/install_fonts.sh .` → `assets/fonts/*.woff2` + `assets/fonts.css` (Unbounded,
Manrope, JetBrains Mono; кириллица+latin с unicode-range). Подключай
`<link rel="stylesheet" href="assets/fonts.css">`. Пути внутри fonts.css относительны
самому файлу (`fonts/…`) — не переноси его в другую папку. Никаких CDN-шрифтов при рендере.

## Команды

```bash
npm run check                                        # линт+валидация, нужен 0 ошибок
npx hyperframes snapshot --at 4,12.5,22              # PNG по таймкодам
npx hyperframes render -q draft -o renders/v1-draft.mp4
npx hyperframes render -q high -o renders/v1.mp4
```

- package.json проекта (скилл пишет сам): скрипты dev/check/render на
  `npx --yes hyperframes@<версия>` — версию фиксируй (проверено: 0.7.62).
  Версия продублирована в `scripts/bootstrap.sh` (HYPERFRAMES_VER) — при обновлении меняй оба.
- Рендер: ~2–2.5× длительности видео на M-серии. Draft заметно быстрее — для ревизий.
- Снапшоты: середины сцен, пики экшена, стыки; `--zoom` для деталей.

## Частые дефекты (см. также troubleshooting.md)

- Тишина → нет `id` у `<audio>`.
- Текст вылезает из карточки → сократи строку (~28 симв. на 470px при 26px), не уменьшай шрифт.
- Текст переносится/рвётся на большом кегле → нет `white-space:nowrap` + явного width (правило 12).
- Градиентный текст невидим / `text_not_painted` → градиент на спанах, не на родителе (правило 11).
- Панель/полоса уехала наверх кадра → дети вне позиционированного контейнера (правило 13).
- Кадры за пределами длительности в snapshot → repeat посчитан от TOTAL, а не от остатка (правило 7).
- Подпись видна раньше времени → анимируй контейнер целиком, а не только детей.
- Видео обрезано → нет `data-duration` на руте / таймлайн короче видео (`tl.set({},{},TOTAL)`).

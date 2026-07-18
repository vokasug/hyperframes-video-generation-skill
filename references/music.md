# Фоновая музыка

## Вариант пользователя всегда в приоритете

Если дан свой файл — используй его (проверь `ffprobe`, что длительность ≥ длины видео;
короче — зацикли или подбери другой отрезок с разрешения пользователя).

## Автоподбор: цепочка источников

Перед поиском ВСЕГДА запусти `scripts/probe_music.sh` — доступность зависит от VPN/сети.
Иди по цепочке до первого живого:

| # | Источник | Лицензия | Как брать |
|---|---|---|---|
| 1 | **Mixkit** (mixkit.co) | Mixkit Free License: коммерция ок, атрибуция не нужна | страница тега `https://mixkit.co/free-stock-music/tag/<тег>/` → из HTML ссылки `https://assets.mixkit.co/music/<id>/<id>.mp3` (прямые mp3) |
| 2 | **Incompetech** (incompetech.com) | CC-BY 4.0 — атрибуция обязательна (укажи в финале/описании: «Music: <название> by Kevin MacLeod, incompetech.com») | каталог → прямые mp3 `https://incompetech.com/music/royalty-free/mp3-royaltyfree/<name>.mp3` |
| 3 | **Free Music Archive** (freemusicarchive.org) | разные CC — проверяй страницу трека | страницы треков, ссылки на скачивание |
| 4 | **Internet Archive** (archive.org) | public domain / CC | поиск `mediatype:audio AND (жанр)` → файлы mp3 |
| 5 | **Wikimedia Commons** (commons.wikimedia.org) | CC-BY / CC-BY-SA / public domain — атрибуция по карточке файла | классика и фортепиано в исполнениях; рецепт ниже |
| 6 | YouTube Audio Library | бесплатно для видео | ТОЛЬКО если youtube.com доступен (обычно = включён VPN): `yt-dlp -x --audio-format mp3 <url>` |

Известная доступность без VPN (проверено на практике, но ВСЕГДА перепроверяй probe):
Mixkit ✅, Incompetech ✅, FMA ✅, archive.org ✅, Wikimedia Commons ✅;
Pixabay ❌, YouTube ❌, SoundCloud ❌, Musopen ❌ (403), Uppbeat ❌ (429).

## Правило теста скорости хоста (важно!)

HEAD/200 ≠ скачивание. В некоторых сетях фильтры режут большие ответы по хостам:
передача обрывается на ~15–150 КБ (curl виснет/таймаутит, файл «валидный», но усечён).
Поэтому КАЖДЫЙ кандидат скачивай сразу целиком и сверяй размер с `Content-Length` и
длительность по ffprobe с ожиданием. Обрыв → следующий источник по цепочке.
Проверено 2026-07: assets.mixkit.co, incompetech.com, archive.org резались ~15–150 КБ;
upload.wikimedia.org отдал 50 МБ за 3 с; dl.google.com, speed.cloudflare.com — полные.

## Wikimedia Commons — рецепт (спасательный круг для классики)

```bash
# 1. Поиск аудиофайлов (namespace 6 = File):
curl -sL "https://commons.wikimedia.org/w/api.php?action=query&list=search\
&srsearch=<запрос, напр. Gymnopédie piano>&srnamespace=6&format=json&srlimit=10"

# 2. URL, размер, длительность, лицензия:
curl -sL "https://commons.wikimedia.org/w/api.php?action=query\
&titles=File:<имя>&prop=imageinfo&iiprop=url|size|extmetadata&format=json"
# extmetadata.LicenseShortName, .Artist — для атрибуции в финале видео

# 3. Скачивание по imageinfo.url (upload.wikimedia.org — быстрый)
```

Проверенный пример: Э. Сати — Gymnopédie No. 1, исп. Daria Baiocchi, CC BY-SA 4.0
(191 с, фортепиано, меланхолия — идеально для книг/историй). WAV конвертируй через
prep_bgm.sh (он же обрежет под длительность и сделает фейды).

## Жанры под тип видео (предлагай в вопросах)

- **lo-fi / chillhop** — дефолт для обучалок: спокойно, не отвлекает
- **корпоративный upbeat** — мотивирующий, для промо и презентаций
- **эмбиент-электроника** — технологичный, для ИИ/науки/космоса
- **кинематографичный минимализм** — драматичный, для историй/книг
- Теги Mixkit под жанры: `corporate`, `ambient`, `chill`, `cinematic`, `electronic`, `happy`

Обязательно: трек **без слов** (инструментал). Кандидата (название + ссылка) покажи
пользователю до рендера.

## Подготовка и уровень

```bash
scripts/prep_bgm.sh <input.mp3> <длительность_видео_сек> assets/bgm.mp3
# = обрезка + фейд-ин 2с + фейд-аут последние 3.5с
```

В композиции: `<audio id="bgm" class="clip" data-start="0" data-duration="<TOTAL>"
data-track-index="3" data-volume="0.14" src="assets/bgm.mp3"/>`.

- Уровень: `data-volume` 0.12–0.15 ≈ −13…−17 дБ под речью — голос чётко поверх.
- Проверка баланса после рендера: `verify_render.sh` — речь mean ≈ −20 dB,
  музыка-only сегменты на 13–17 дБ ниже.
- Музыка НЕ должна заканчиваться раньше видео: `data-duration` = длине видео, файл bgm.mp3
  готовь с запасом (+0.3 с).

## Без музыки

Допустимо (подкаст-стиль). Тогда проверяй, что сцены не «провисают» без фона — держи темп
монтажа плотнее (паддинги 0.3–0.4 с).

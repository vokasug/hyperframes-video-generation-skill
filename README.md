# hyperframes-video-generation-skill

Скилл для ИИ-агентов (OpenCode, Claude Code и др.): полный цикл создания видео с озвучкой —
от изучения источника и сценария до TTS-озвучки, HTML-анимации и готового MP4.

Генерирует обучающие эксплейнеры, видео по книгам (сюжет, смысл, мораль), обзоры, промо,
отчёты и сторителлинг. Вход — файл (md/txt/pdf), текст, ссылка или просто тема. Выход —
готовый MP4 с озвучкой (русской по умолчанию), фоновой музыкой и современной моушн-графикой.

## Возможности

- **Сценарий и раскадровка** из источника (файл, текст, тема — фактура собирается из интернета),
  с тремя обязательными точками ревизии с пользователем
- **Озвучка** бесплатным edge-tts (без API-ключей): десятки голосов, per-scene MP3 + SRT,
  поддержка подкаст-диалогов двумя и более голосами
- **Анимация** на HTML + GSAP через [hyperframes](https://www.npmjs.com/package/hyperframes):
  15+ проверенных сцен-архетипов, 4 пресета стиля, забандленные шрифты с кириллицей
  (Unbounded, Manrope, JetBrains Mono)
- **Фоновая музыка** с автоподбором из свободных источников (Mixkit → Incompetech → FMA →
  Internet Archive → Wikimedia Commons), обрезка и фейды под длительность
- **Проверка результата**: ffprobe, баланс голос/музыка, контрольные кадры из готового MP4
- Полностью автономен; если установлены скиллы `hyperframes-*` / `media-use`, подключает их
  как опциональные усилители

## Требования

- macOS (установка через Homebrew; на Linux проверка окружения работает, установка — вручную)
- Node.js ≥ 22, ffmpeg, edge-tts (pipx), опционально yt-dlp

## Установка

Склонируйте репозиторий в папку скиллов вашего агента:

```bash
# OpenCode
git clone https://github.com/vokasug/hyperframes-video-generation-skill \
  ~/.config/opencode/skills/hyperframes-video-generation

# Claude Code
git clone https://github.com/vokasug/hyperframes-video-generation-skill \
  ~/.claude/skills/hyperframes-video-generation
```

Проверка окружения (и установка недостающего на macOS):

```bash
bash ~/.config/opencode/skills/hyperframes-video-generation/scripts/bootstrap.sh --check
bash ~/.config/opencode/skills/hyperframes-video-generation/scripts/bootstrap.sh --install
```

## Использование

Просто скажите агенту, например:

- «Сделай видео по этой статье» (и приложите файл)
- «Создай обучающее видео про LLM-агентов на 2 минуты»
- «Сделай подкаст-разбор книги "Идиот" двумя голосами»

Скилл сам задаст уточняющие вопросы (одним блоком, с дефолтами), покажет бриф и раскадровку,
озвучит, соберёт анимацию и отрендерит MP4 — с ревизиями на каждом ключевом этапе.

## Структура

```
SKILL.md        — точка входа: правила, воркфлоу (8 этапов, 3 ревизии)
references/     — справочники: пайплайн, сценарии, стили, сцены, TTS, музыка, контракт
scripts/        — bootstrap, TTS по сценам, таймлайн, подготовка BGM, проверка рендера
assets/         — шрифты (woff2, кириллица) + fonts.css
```

## Лицензии

- Код и документация: [MIT](LICENSE)
- Шрифты в `assets/fonts/`: [SIL Open Font License 1.1](assets/fonts/OFL.txt)
  (Unbounded, Manrope, JetBrains Mono — Google Fonts)

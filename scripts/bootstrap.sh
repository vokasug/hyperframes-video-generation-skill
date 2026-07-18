#!/usr/bin/env bash
# bootstrap.sh — проверка/установка окружения для hyperframes-video-generation
# Использование: bootstrap.sh [--check|--install]
set -uo pipefail
MODE="${1:---check}"
HYPERFRAMES_VER="0.7.62"

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
miss() { printf "  \033[31m✗\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }

node_ok=0; ffmpeg_ok=0; tts_ok=0; ytdlp_ok=0

echo "== Инструменты =="
if command -v node >/dev/null 2>&1; then
  NV=$(node -e "console.log(process.versions.node.split('.')[0])" 2>/dev/null || echo 0)
  if [ "$NV" -ge 22 ]; then ok "node $(node --version)"; node_ok=1; else miss "node $(node --version) — нужна >= 22"; fi
else miss "node не найден"; fi

if command -v ffmpeg >/dev/null 2>&1; then ok "ffmpeg $(ffmpeg -version 2>/dev/null | head -1 | awk '{print $3}')"; ffmpeg_ok=1; else miss "ffmpeg не найден"; fi

if command -v edge-tts >/dev/null 2>&1; then ok "edge-tts $(edge-tts --version 2>/dev/null)"; tts_ok=1; else miss "edge-tts не найден"; fi

if command -v yt-dlp >/dev/null 2>&1; then ok "yt-dlp (опционально) $(yt-dlp --version 2>/dev/null)"; ytdlp_ok=1; else warn "yt-dlp нет (опционально, музыка через YouTube)"; fi

echo "== hyperframes (npx-кэш) =="
if [ "$MODE" = "--install" ]; then
  npx --yes "hyperframes@${HYPERFRAMES_VER}" --version >/dev/null 2>&1 && ok "hyperframes ${HYPERFRAMES_VER} закэширован" || warn "npx hyperframes не ответил"
else
  ok "будет вызван как: npx --yes hyperframes@${HYPERFRAMES_VER} (глобальная установка не нужна)"
fi

if [ "$MODE" = "--install" ]; then
  echo "== Установка недостающего =="
  if ! command -v brew >/dev/null 2>&1; then echo "Homebrew не найден — установи brew первым: https://brew.sh"; exit 1; fi
  [ "$node_ok" = 0 ]   && { echo "brew install node";   brew install node; }
  [ "$ffmpeg_ok" = 0 ] && { echo "brew install ffmpeg"; brew install ffmpeg; }
  if [ "$tts_ok" = 0 ]; then
    command -v pipx >/dev/null 2>&1 || { echo "brew install pipx"; brew install pipx; }
    echo "pipx install edge-tts"; pipx install edge-tts || pipx upgrade edge-tts
  fi
  [ "$ytdlp_ok" = 0 ] && { echo "brew install yt-dlp (опционально)"; brew install yt-dlp || true; }
fi

echo "== Усилители (скиллы hyperframes, опционально) =="
FOUND=$(ls ~/.config/opencode/skills/ ~/.claude/skills/ 2>/dev/null | grep -E "^(hyperframes|media-use)" | grep -v "hyperframes-video-generation" | sort -u | tr '\n' ' ')
if [ -n "$FOUND" ]; then echo "  найдены: $FOUND"; else echo "  не найдены — воркфлоу пойдёт автономно (это нормально)"; fi

echo "== Итог =="
if [ "$node_ok" = 1 ] && [ "$ffmpeg_ok" = 1 ] && [ "$tts_ok" = 1 ]; then
  ok "окружение готово к созданию видео"; exit 0
else
  if [ "$MODE" = "--install" ]; then
    command -v node >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1 && command -v edge-tts >/dev/null 2>&1 && { ok "окружение готово"; exit 0; }
  fi
  miss "есть недостающие инструменты — запусти: bootstrap.sh --install"; exit 1
fi

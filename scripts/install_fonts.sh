#!/usr/bin/env bash
# install_fonts.sh — копия забандленных шрифтов скилла в проект
# Использование: install_fonts.sh <project_dir>
# Результат: <project>/assets/fonts/*.woff2 + <project>/assets/fonts.css
set -euo pipefail
PROJECT="${1:?укажи папку проекта}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$PROJECT/assets/fonts"
cp "$SKILL_DIR"/assets/fonts/*.woff2 "$PROJECT/assets/fonts/"
cp "$SKILL_DIR/assets/fonts.css" "$PROJECT/assets/fonts.css"
count=$(ls "$PROJECT/assets/fonts"/*.woff2 | wc -l | tr -d ' ')
if [ "$count" -ge 20 ]; then
  echo "шрифты установлены: $count файлов -> $PROJECT/assets/fonts + fonts.css"
else
  echo "в бандле мало файлов ($count) — докачиваю с Google Fonts"
  python3 "$SKILL_DIR/scripts/fetch_fonts.py" "$PROJECT/assets"
fi

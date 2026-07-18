#!/usr/bin/env bash
# tts_scenes.sh — озвучка всех сцен из папки + SRT + замер длительностей
# Использование: tts_scenes.sh <dir_txt> <dir_out> [voice] [rate]
# Пример: tts_scenes.sh script assets/vo ru-RU-DmitryNeural +5%
set -euo pipefail
TXT_DIR="${1:?нужна папка с txt-сценами}"
OUT_DIR="${2:?нужна папка вывода}"
VOICE="${3:-ru-RU-DmitryNeural}"
RATE="${4:-+5%}"
mkdir -p "$OUT_DIR"
for f in "$TXT_DIR"/*.txt; do
  n=$(basename "$f" .txt)
  edge-tts --voice "$VOICE" --rate="$RATE" --file "$f" \
    --write-media "$OUT_DIR/$n.mp3" --write-subtitles "$OUT_DIR/$n.srt" >/dev/null 2>&1
  echo "  $n.mp3"
done
echo "== Длительности =="
total=0
for m in "$OUT_DIR"/*.mp3; do
  d=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$m")
  total=$(echo "$total + $d" | bc)
  printf "  %-28s %6.2f c\n" "$(basename "$m")" "$d"
done
n=$(ls "$OUT_DIR"/*.mp3 | wc -l | tr -d ' ')
over=$(echo "$n * 0.55" | bc)
printf "Сцен: %s · речь: %.2f c · видео ≈ %.2f c (речь + %.2f c паддинги)\n" "$n" "$total" "$(echo "$total + $over" | bc)" "$over"

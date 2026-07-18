#!/usr/bin/env bash
# prep_bgm.sh — фоновая музыка под длительность видео: обрезка/луп + фейды
# Использование: prep_bgm.sh <input> <duration_sec> <output>
set -euo pipefail
IN="${1:?входной файл музыки}"
DUR="${2:?длительность видео, сек}"
OUT="${3:?выходной файл}"
FADE_OUT_START=$(echo "$DUR - 3.5" | bc)
ffmpeg -y -v error -stream_loop -1 -i "$IN" -t "$(echo "$DUR + 0.3" | bc)" \
  -af "afade=t=in:st=0:d=2,afade=t=out:st=${FADE_OUT_START}:d=3.5" -q:a 4 "$OUT"
echo "bgm готов: $OUT ($(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUT") c)"
echo "в композицию: <audio id=\"bgm\" class=\"clip\" data-start=\"0\" data-duration=\"$DUR\" data-track-index=\"3\" data-volume=\"0.14\" src=\"assets/bgm.mp3\"/>"

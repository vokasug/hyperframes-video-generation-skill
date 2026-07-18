#!/usr/bin/env bash
# verify_render.sh — проверка готового MP4: формат, звук, кадры
# Использование: verify_render.sh <video.mp4> [speech_start] [speech_len]
set -euo pipefail
V="${1:?путь к mp4}"
SS="${2:-20}"; SL="${3:-10}"
echo "== Формат =="
ffprobe -v quiet -show_entries format=duration,size:stream=codec_type,codec_name,width,height,r_frame_rate,channels -of default=noprint_wrappers=1 "$V"
echo "== Громкость (речь, t=${SS}s +${SL}s) =="
ffmpeg -ss "$SS" -t "$SL" -i "$V" -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume" || true
echo "== Громкость (интегральная) =="
ffmpeg -i "$V" -af loudnorm=print_format=summary -f null - 2>&1 | grep -E "Input Integrated|Input True Peak" || true
FRAMES_DIR="$(dirname "$V")/verify-frames"
mkdir -p "$FRAMES_DIR"
TOTAL=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$V")
i=0
for pct in 5 10 20 30 40 50 60 70 80 90 95; do
  t=$(echo "$TOTAL * $pct / 100" | bc -l | cut -d. -f1)
  if [ -n "$t" ] && [ "$t" -lt "${TOTAL%.*}" ]; then
    ffmpeg -y -v error -ss "$t" -i "$V" -frames:v 1 "$FRAMES_DIR/frame-${t}s.jpg"
    i=$((i+1))
  fi
done
echo "кадры для ревизии: $i шт (по долям длительности ${TOTAL%.*} c) -> $FRAMES_DIR"

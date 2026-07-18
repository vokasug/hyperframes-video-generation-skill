#!/usr/bin/env bash
# probe_music.sh — доступность источников фоновой музыки с этой машины
set -uo pipefail
check() {
  local name="$1" url="$2"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -I --max-time 5 -L "$url" 2>/dev/null || true); [ -z "$code" ] && code=000
  if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
    printf "  \033[32m✓\033[0m %-28s %s\n" "$name" "$url"
  else
    printf "  \033[31m✗\033[0m %-28s %s (HTTP %s)\n" "$name" "$url" "$code"
  fi
}
echo "Доступность источников музыки (без учёта VPN):"
check "Mixkit (основной)"        "https://mixkit.co"
check "Mixkit assets (mp3)"      "https://assets.mixkit.co"
check "Incompetech (CC-BY)"      "https://incompetech.com"
check "Free Music Archive"       "https://freemusicarchive.org"
check "Internet Archive"         "https://archive.org"
check "Wikimedia Commons"        "https://commons.wikimedia.org"
check "YouTube (нужен VPN)"      "https://www.youtube.com"
check "Pixabay"                  "https://pixabay.com"
echo "Цепочка выбора: Mixkit → Incompetech → FMA → Internet Archive → Wikimedia Commons → (YouTube, если доступен)"

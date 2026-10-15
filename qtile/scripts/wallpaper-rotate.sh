#!/usr/bin/env bash
#
# wallpaper-rotate.sh — kiest een andere wallpaper en past het kleurenschema toe.
#
# Wordt elke 10 minuten aangeroepen door de systemd-user-timer
# 'wallpaper-rotate.timer' (zie systemd/wallpaper-rotate.{service,timer}).
# Handmatig draaien kan ook: er wordt een willekeurige wallpaper gekozen die
# niet de huidige is.
#
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.local/share/wallpapers}"
WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

shopt -s nullglob
imgs=(
    "${WALLPAPER_DIR}"/*.jpg "${WALLPAPER_DIR}"/*.jpeg
    "${WALLPAPER_DIR}"/*.png "${WALLPAPER_DIR}"/*.webp
)
shopt -u nullglob

if [[ ${#imgs[@]} -eq 0 ]]; then
    echo "wallpaper-rotate: geen afbeeldingen in ${WALLPAPER_DIR}" >&2
    exit 1
fi

# Huidige wallpaper (zodat er niet twee keer achter elkaar dezelfde komt).
current=""
if [[ -f "${WAL_CACHE}/colors.json" ]]; then
    current="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("wallpaper",""))' \
        "${WAL_CACHE}/colors.json" 2>/dev/null || true)"
fi

candidates=()
for f in "${imgs[@]}"; do
    [[ "${f}" == "${current}" ]] || candidates+=("${f}")
done
# Als er maar één wallpaper is, valt er niets te wisselen: gebruik toch alles.
[[ ${#candidates[@]} -gt 0 ]] || candidates=("${imgs[@]}")

if command -v shuf >/dev/null 2>&1; then
    next="$(printf '%s\n' "${candidates[@]}" | shuf -n 1)"
else
    next="${candidates[$((RANDOM % ${#candidates[@]}))]}"
fi

echo "wallpaper-rotate: $(date '+%F %T') -> $(basename "${next}")"

exec "${SCRIPT_DIR}/set-wallpaper.sh" "${next}"

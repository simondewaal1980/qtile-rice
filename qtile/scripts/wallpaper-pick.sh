#!/usr/bin/env bash
#
# wallpaper-pick.sh — kies een wallpaper met rofi (galerij met thumbnails) en
#                     pas daarna automatisch het kleurenschema aan.
#
# Gebonden aan mod+shift+w in config.py.
#
set -euo pipefail

WALLPAPER_DIR="${HOME}/.local/share/wallpapers"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wal-thumbs"

mkdir -p "${THUMB_DIR}"

# ImageMagick 7 gebruikt 'magick'; oudere versies 'convert'.
if command -v magick >/dev/null 2>&1; then
    IM=magick
else
    IM=convert
fi

shopt -s nullglob
imgs=()
for f in "${WALLPAPER_DIR}"/*; do
    case "${f,,}" in
        *.jpg|*.jpeg|*.png|*.webp|*.bmp) imgs+=("${f}") ;;
    esac
done
shopt -u nullglob

if [[ ${#imgs[@]} -eq 0 ]]; then
    msg="Geen afbeeldingen gevonden in ${WALLPAPER_DIR}"
    notify-send "Wallpaper" "${msg}" 2>/dev/null || echo "${msg}" >&2
    exit 1
fi

# rofi dmenu met icoon per regel ("naam\0icon\x1f<pad>"): zo zie je een
# thumbnail als preview. Thumbnails worden gecached in ~/.cache/wal-thumbs.
choice="$(
    for img in "${imgs[@]}"; do
        base="$(basename "${img}")"
        thumb="${THUMB_DIR}/${base}.png"
        if [[ ! -f "${thumb}" || "${img}" -nt "${thumb}" ]]; then
            "${IM}" "${img}" -thumbnail '512x288^' -gravity center -extent 512x288 \
                "${thumb}" 2>/dev/null || thumb="${img}"
        fi
        printf '%s\0icon\x1f%s\n' "${base}" "${thumb}"
    done | rofi -dmenu -i -p 'Wallpaper' -show-icons \
        -theme-str 'element-icon { size: 8em; } listview { lines: 4; }'
)" || exit 0

[[ -z "${choice}" ]] && exit 0

exec "${SCRIPT_DIR}/set-wallpaper.sh" "${WALLPAPER_DIR}/${choice}"

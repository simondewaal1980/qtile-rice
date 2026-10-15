#!/usr/bin/env bash
#
# set-wallpaper.sh — genereert een kleurenschema uit de wallpaper met pywal
#                     en past dat toe op qtile, rofi, alacritty en GTK-apps.
#
# Gebruik:
#   set-wallpaper.sh [pad/naar/afbeelding]
#
# Zonder argument wordt de laatst gebruikte wallpaper (uit pywal) gebruikt,
# of anders de standaard acropolis.jpg.
#
set -euo pipefail

WALLPAPER_DIR="${HOME}/.local/share/wallpapers"
WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
DEFAULT_WALL="${WALLPAPER_DIR}/acropolis.jpg"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

if ! command -v wal >/dev/null 2>&1; then
    echo "set-wallpaper: 'wal' (pywal) is niet gevonden." >&2
    exit 1
fi

img="${1:-}"

# Geen argument? Gebruik de wallpaper die pywal als laatste gebruikte.
if [[ -z "${img}" && -f "${WAL_CACHE}/colors.json" ]]; then
    img="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("wallpaper",""))' \
        "${WAL_CACHE}/colors.json" 2>/dev/null || true)"
fi

[[ -n "${img}" && -f "${img}" ]] || img="${DEFAULT_WALL}"

if [[ ! -f "${img}" ]]; then
    echo "set-wallpaper: afbeelding niet gevonden: ${img}" >&2
    exit 1
fi

# 1. Kleuren genereren. '-n' laat pywal de wallpaper NIET zetten: qtile tekent
#    de achtergrond zelf (via de Screen-configuratie in config.py).
wal -i "${img}" -n

# 2. X-resources (xterm/urxvt e.a.) — pywal doet dit ook, expliciet voor de zekerheid.
if command -v xrdb >/dev/null 2>&1 && [[ -f "${WAL_CACHE}/colors.Xresources" ]]; then
    xrdb -merge -quiet "${WAL_CACHE}/colors.Xresources"
fi

# 3. GTK3/GTK4-apps.
if [[ -x "${SCRIPT_DIR}/apply-gtk-theme.sh" ]]; then
    "${SCRIPT_DIR}/apply-gtk-theme.sh"
fi

# 4. qtile herladen zodat de nieuwe kleuren en wallpaper actief worden.
if command -v qtile >/dev/null 2>&1; then
    qtile cmd-obj -o cmd -f reload_config >/dev/null 2>&1 || true
fi

#!/usr/bin/env bash
#
# spotify-theme.sh — past het door pywal gegenereerde kleurenschema toe op
#                    de Spotify-client (via Spicetify).
#
#   * leest de kleuren uit ~/.cache/wal/colors.json
#   * schrijft ~/.config/spicetify/Themes/Pywal/color.ini
#   * zet het thema actief en draait 'spicetify apply'
#
# Wordt automatisch aangeroepen door set-wallpaper.sh (dus bij elke
# wallpaperwissel). Handmatig draaien kan ook.
#
# Let op: een draaiende Spotify pikt het nieuwe thema pas op na een herstart.
# Na een Spotify-update moet eenmalig 'spicetify backup apply' worden gedraaid.
#
set -euo pipefail

WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
COLORS_JSON="${WAL_CACHE}/colors.json"
SPICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/spicetify"
THEME_DIR="${SPICE_DIR}/Themes/Pywal"
COLOR_INI="${THEME_DIR}/color.ini"

if [[ ! -f "${COLORS_JSON}" ]]; then
    echo "spotify-theme: ${COLORS_JSON} ontbreekt (draai eerst 'wal')." >&2
    exit 1
fi

mkdir -p "${THEME_DIR}"

python3 - "${COLORS_JSON}" "${COLOR_INI}" <<'PY'
"""Bouw een Spicetify-color.ini op uit de pywal-palet.

De accentkleuren komen rechtstreeks uit het palet; de neutrale tinten
(oppervlakken, randen, gedempte tekst) worden uit de achtergrond- en
voorgrondkleur gemengd, zodat het thema bij elk palet klopt.
"""
import colorsys
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path, encoding="utf-8") as fh:
    pal = json.load(fh)

bg = pal["special"]["background"]
fg = pal["special"]["foreground"]
palette = pal["colors"]


def to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def to_hex(rgb):
    return "%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in rgb)


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def lighten(rgb, amount):
    return mix(rgb, (255, 255, 255), amount)


def darken(rgb, amount):
    return mix(rgb, (0, 0, 0), amount)


BG, FG = to_rgb(bg), to_rgb(fg)
C = {i: to_rgb(palette[f"color{i}"]) for i in range(16)}


def luminance(rgb):
    def channel(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsv(rgb):
    return colorsys.rgb_to_hsv(*(v / 255 for v in rgb))


# Kies het meest uitgesproken accent uit de kleurige palletslots (1-6).
# Pywal sorteert de kleuren op hue, dus het accent staat niet bij elke
# wallpaper op dezelfde plek; de meest verzadigde kleur is het veiligst.
accent_index = max(range(1, 7), key=lambda i: hsv(C[i])[1] * hsv(C[i])[2])
accent = C[accent_index]

# Houd het accent licht genoeg voor een leesbaar (donker) icoon op de
# play-knop, ook bij donkere of gedempte paletten.
while luminance(accent) < 0.18:
    accent = lighten(accent, 0.06)

accent_bright = lighten(accent, 0.28)

colors = {
    "text": FG,
    "subtext": mix(FG, BG, 0.32),
    "main": BG,
    "main-elevated": lighten(BG, 0.06),
    "highlight": mix(BG, accent, 0.20),
    "highlight-elevated": mix(BG, accent, 0.32),
    "sidebar": darken(BG, 0.18),
    "player": lighten(BG, 0.035),
    "card": lighten(BG, 0.09),
    "shadow": darken(BG, 0.55),
    "selected-row": accent_bright,
    "button": accent,
    "button-active": accent_bright,
    "button-disabled": mix(BG, FG, 0.30),
    "tab-active": mix(BG, accent, 0.32),
    "notification": accent,
    "notification-error": C[1],
    "misc": mix(FG, BG, 0.45),
}

lines = [
    "; Automatisch gegenereerd uit de pywal-palet. Niet handmatig aanpassen.",
    "; Bron: ~/.cache/wal/colors.json — wissel van wallpaper voor nieuwe kleuren.",
    "",
    "[Pywal]",
]
for key, rgb in colors.items():
    lines.append(f"{key:<19}= {to_hex(rgb)}")

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY

# Zonder Spicetify is er niets toe te passen; color.ini is dan wel klaar.
if ! command -v spicetify >/dev/null 2>&1; then
    echo "spotify-theme: 'spicetify' niet gevonden; color.ini is wel bijgewerkt." >&2
    exit 0
fi

if [[ ! -f "${SPICE_DIR}/config-xpui.ini" ]]; then
    echo "spotify-theme: Spicetify is nog niet ingesteld; color.ini is wel bijgewerkt." >&2
    exit 0
fi

spicetify config current_theme Pywal color_scheme Pywal >/dev/null

# 'refresh' werkt alleen de kleuren/CSS bij (snel, genoeg bij een
# wallpaperwissel). Lukt dat niet, dan valt het script terug op 'apply'.
if ! spicetify -q refresh >/dev/null 2>&1; then
    if ! spicetify -q apply >/dev/null 2>&1; then
        echo "spotify-theme: 'spicetify apply' mislukte. Draait Spotify? Herstart dan" >&2
        echo "spotify-theme: Spotify, of draai na een update 'spicetify backup apply'." >&2
        exit 1
    fi
fi

if pgrep -f 'com\.spotify\.Client' >/dev/null 2>&1; then
    echo "spotify-theme: thema bijgewerkt; herstart Spotify om het te zien."
else
    echo "spotify-theme: thema bijgewerkt -> ${COLOR_INI}"
fi

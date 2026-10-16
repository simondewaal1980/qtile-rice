#!/usr/bin/env bash
#
# opencode-theme.sh — genereert een OpenCode-thema uit het door pywal
#                     gegenereerde kleurenschema (~/.cache/wal/colors.json)
#                     en schrijft het naar ~/.config/opencode/themes/wal.json.
#
# Wordt automatisch aangeroepen door set-wallpaper.sh, zodat het thema
# meebeweegt met de wallpaper (net als de GTK- en dunst-thema's).
#
# Het thema heet 'wal'; selecteren gebeurt in ~/.config/opencode/cli.json:
#   { "theme": { "name": "wal", "mode": "dark" } }
#
set -euo pipefail

WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
COLORS_JSON="${WAL_CACHE}/colors.json"
THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/themes"
THEME_FILE="${THEME_DIR}/wal.json"

if [[ ! -f "${COLORS_JSON}" ]]; then
    echo "opencode-theme: ${COLORS_JSON} ontbreekt (draai eerst 'wal')." >&2
    exit 1
fi

mkdir -p "${THEME_DIR}"

python3 - "${COLORS_JSON}" "${THEME_FILE}" <<'PY'
"""Bouw een volledig OpenCode-thema op uit de pywal-palet.

De 200-stap van elke 'hue' is exact de bijbehorende pywal-kleur, zodat de
semantische tokens (fouten, syntax, links, ...) letterlijk dezelfde kleuren
gebruiken als de rest van de desktop. De overige stappen zijn lichtere/
donkerdere varianten daarvan. Het neutrale palet (tekst, oppervlakken,
randen) komt uit achtergrond- en voorgrondkleur van pywal.
"""
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path, encoding="utf-8") as fh:
    pal = json.load(fh)

bg = pal["special"]["background"]
fg = pal["special"]["foreground"]
c = pal["colors"]


def to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def to_hex(rgb):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in rgb)


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def lighten(rgb, amount):
    return mix(rgb, (255, 255, 255), amount)


def darken(rgb, amount):
    return mix(rgb, (0, 0, 0), amount)


BG, FG = to_rgb(bg), to_rgb(fg)


def hue_scale(base):
    """Negen stappen; stap 200 is exact de opgegeven pywal-kleur."""
    rgb = to_rgb(base)
    return {
        "100": to_hex(lighten(rgb, 0.50)),
        "200": to_hex(rgb),
        "300": to_hex(darken(rgb, 0.12)),
        "400": to_hex(darken(rgb, 0.26)),
        "500": to_hex(darken(rgb, 0.40)),
        "600": to_hex(darken(rgb, 0.52)),
        "700": to_hex(darken(rgb, 0.64)),
        "800": to_hex(darken(rgb, 0.76)),
        "900": to_hex(darken(rgb, 0.86)),
    }


# Neutrale schaal: 200 = voorgrond, 800 = achtergrond, daartussen de
# verhoogde oppervlakken (raised.base/high/max).
gray = {
    "100": to_hex(lighten(FG, 0.45)),
    "200": to_hex(FG),
    "300": to_hex(mix(FG, BG, 0.30)),
    "400": to_hex(mix(FG, BG, 0.55)),
    "500": to_hex(lighten(BG, 0.24)),
    "600": to_hex(lighten(BG, 0.15)),
    "700": to_hex(lighten(BG, 0.07)),
    "800": to_hex(BG),
    "900": to_hex(darken(BG, 0.45)),
}

dark_hue = {
    "gray": gray,
    "red": hue_scale(c["color1"]),
    "orange": hue_scale(c["color3"]),
    "green": hue_scale(c["color2"]),
    "cyan": hue_scale(c["color6"]),
    "blue": hue_scale(c["color4"]),
    "purple": hue_scale(c["color5"]),
    "accent": "$hue.purple",
    "interactive": "$hue.orange",
    "neutral": "$hue.gray",
}

# De gedeelde tokenboom. Komt overeen met het ingebouwde 'opencode'-thema;
# alleen de letterlijke kleuren hieronder worden op het palet afgestemd.
BASE = json.loads(r"""{"categorical":["blue","purple","green","orange","red"],"text":{"base":"$hue.neutral.200","muted":"$hue.neutral.400","action":{"primary":{"base":"$text.base","$disabled":"$hue.neutral.400","$focused":"$hue.neutral.800","$selected":"$hue.interactive.200"},"secondary":{"base":"$text.muted","$hovered":"$text.base"},"destructive":{"base":"$hue.neutral.800","$disabled":"$hue.neutral.400"}},"formfield":{"base":"$hue.neutral.200","$hovered":"$hue.interactive.200","$focused":"$hue.interactive.200","$pressed":"$hue.interactive.200","$disabled":"$hue.neutral.400","$selected":"$hue.interactive.200"},"feedback":{"error":{"base":"$hue.red.200"},"warning":{"base":"#f5a742"},"success":{"base":"$hue.green.200"},"info":{"base":"$hue.cyan.200"}}},"background":{"base":"$hue.neutral.800","raised":{"base":"$hue.neutral.700","high":"$hue.neutral.600","max":"$hue.neutral.500"},"action":{"primary":{"base":"transparent","$hovered":"$hue.neutral.700","$focused":"$hue.interactive.200","$selected":"transparent"},"secondary":{"base":"transparent"},"destructive":{"base":"$hue.red.200"}},"formfield":{"base":"$background.base"},"feedback":{"error":{"base":"$background.base"},"warning":{"base":"$background.base"},"success":{"base":"$background.base"},"info":{"base":"$background.base"}}},"border":{"base":"#484848"},"scrollbar":{"base":"#606060"},"diff":{"text":{"added":"#4fd6be","removed":"#c53b53","context":"#828bb8","hunkHeader":"#828bb8"},"background":{"added":"#20303b","removed":"#37222c","context":"$hue.neutral.700"},"highlight":{"added":"#b8db87","removed":"#e26a75"},"lineNumber":{"text":"#8f8f8f","background":{"added":"#1b2b34","removed":"#2d1f26"}}},"syntax":{"comment":"$hue.neutral.400","keyword":"$hue.accent.200","function":"$hue.interactive.200","variable":"$hue.red.200","string":"$hue.green.200","number":"#f5a742","type":"#e5c07b","operator":"$hue.cyan.200","punctuation":"$hue.neutral.200"},"markdown":{"text":"$hue.neutral.200","heading":"$hue.accent.200","link":"$hue.interactive.200","linkText":"$hue.cyan.200","code":"$hue.green.200","blockQuote":"#e5c07b","emphasis":"#e5c07b","strong":"#f5a742","horizontalRule":"$hue.neutral.400","listItem":"$hue.interactive.200","listEnumeration":"$hue.cyan.200","image":"$hue.interactive.200","imageText":"$hue.cyan.200","codeBlock":"$hue.neutral.200"},"@dialog":{"background":{"base":"$background.raised.base","action":{"primary":{"$hovered":"$background.raised.high"}}}}}""")

BASE["text"]["feedback"]["warning"]["base"] = "$hue.orange.200"
BASE["border"]["base"] = to_hex(mix(BG, FG, 0.22))
BASE["scrollbar"]["base"] = to_hex(mix(BG, FG, 0.33))

BASE["syntax"].update({
    "number": "$hue.orange.100",
    "type": "$hue.cyan.100",
})

BASE["markdown"].update({
    "blockQuote": "$hue.orange.100",
    "emphasis": "$hue.orange.100",
    "strong": "$hue.orange.200",
})

green, red = to_rgb(c["color2"]), to_rgb(c["color1"])
BASE["diff"] = {
    "text": {
        "added": "$hue.green.200",
        "removed": "$hue.red.200",
        "context": "$hue.neutral.400",
        "hunkHeader": "$hue.neutral.400",
    },
    "background": {
        "added": to_hex(mix(BG, green, 0.16)),
        "removed": to_hex(mix(BG, red, 0.16)),
        "context": "$hue.neutral.700",
    },
    "highlight": {
        "added": "$hue.green.100",
        "removed": "$hue.red.100",
    },
    "lineNumber": {
        "text": "$hue.neutral.400",
        "background": {
            "added": to_hex(mix(BG, green, 0.10)),
            "removed": to_hex(mix(BG, red, 0.10)),
        },
    },
}

theme = {
    "$schema": "https://opencode.ai/theme.json",
    "base": BASE,
    "dark": {"hue": dark_hue},
}

with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(theme, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY

echo "opencode-theme: thema bijgewerkt -> ${THEME_FILE}"

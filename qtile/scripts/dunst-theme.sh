#!/usr/bin/env bash
#
# dunst-theme.sh — past het door pywal gegenereerde kleurenschema toe op dunst.
#
#   * leest de kleuren uit ~/.cache/wal/colors.sh
#   * schrijft ~/.config/dunst/dunstrc
#   * laat een draaiende dunst de nieuwe config herladen
#
# Wordt automatisch aangeroepen door set-wallpaper.sh (dus bij elke
# wallpaperwissel). Handmatig draaien kan ook.
#
set -euo pipefail

WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
COLORS_SH="${WAL_CACHE}/colors.sh"
DUNST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dunst"
DUNSTRC="${DUNST_DIR}/dunstrc"

if [[ ! -f "${COLORS_SH}" ]]; then
    echo "dunst-theme: ${COLORS_SH} ontbreekt (draai eerst 'wal')." >&2
    exit 1
fi

# colors.sh verwijst naar $FZF_DEFAULT_OPTS/$LS_COLORS die nog niet bestaan;
# daarom 'set -u' even uitzetten tijdens het inlezen.
# shellcheck disable=SC1090
set +u
source "${COLORS_SH}"   # levert $background, $foreground, $color0..$color15
set -u

mkdir -p "${DUNST_DIR}"

# Kleurtoewijzing (sluit aan op apply-gtk-theme.sh):
#   accent / normaal  -> color2
#   laag             -> color8 (gedempt)
#   kritiek          -> color1 (foutkleur)
cat > "${DUNSTRC}" <<EOF
# Automatisch gegenereerd uit de wallpaper (pywal). Niet handmatig aanpassen.
# Pas het thema aan via ~/.config/qtile/scripts/dunst-theme.sh of kies een
# nieuwe wallpaper (Super+Shift+w).

[global]
    ### Weergave ###
    font = Noto Sans 10
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    line_height = 0
    show_age_threshold = 60
    indicate_hidden = yes
    show_indicators = yes
    sort = yes
    stack_duplicates = true
    hide_duplicate_count = false

    ### Positie en grootte ###
    width = 340
    height = (0, 200)
    origin = top-right
    offset = (12, 12)
    notification_limit = 5
    gap_size = 6
    padding = 12
    horizontal_padding = 14
    text_icon_padding = 0
    separator_height = 2
    separator_color = frame
    frame_width = 2
    corner_radius = 8
    transparency = 0

    ### Voortgangsbalk ###
    progress_bar = true
    progress_bar_height = 8
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 340

    ### Iconen ###
    icon_position = left
    icon_theme = Adwaita
    min_icon_size = 16
    max_icon_size = 48
    icon_path = /usr/share/icons/Adwaita/16x16/status/:/usr/share/icons/Adwaita/16x16/devices/:/usr/share/icons/hicolor/48x48/apps/

    ### Geschiedenis en gedrag ###
    idle_threshold = 120
    sticky_history = yes
    history_length = 20
    always_run_script = true

    ### Overig ###
    title = Dunst
    class = Dunst
    ignore_dbusclose = false
    force_xwayland = false

    mouse_left_click = close_current
    mouse_middle_click = do_action
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "${background}"
    foreground = "${foreground}"
    frame_color = "${color8}"
    timeout = 5

[urgency_normal]
    background = "${background}"
    foreground = "${foreground}"
    frame_color = "${color2}"
    timeout = 10

[urgency_critical]
    background = "${background}"
    foreground = "${foreground}"
    frame_color = "${color1}"
    timeout = 0
EOF

# Een draaiende dunst meteen het nieuwe thema laten oppikken.
if command -v dunstctl >/dev/null 2>&1 && pgrep -x dunst >/dev/null 2>&1; then
    dunstctl reload >/dev/null 2>&1 || true
fi

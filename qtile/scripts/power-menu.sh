#!/usr/bin/env bash
#
# power-menu.sh — dropdownmenu achter de power-knop in de qtile-balk.
#
# Toont met rofi een klein menu met uitzetten, opnieuw opstarten en
# uitloggen. De power-knop staat rechts in de bovenbalk; het menu wordt
# daarom rechtsboven, direct onder de balk, geplaatst.

set -u

# Rofi centreert zijn venster standaard. Reken de offsets uit zodat het menu
# toch onder de power-knop (rechtsboven) verschijnt.
menu_w=250
menu_h=168
margin_x=8
margin_y=6
bar_h=44

screen_w=1920
screen_h=1080
if command -v xrandr >/dev/null 2>&1; then
    if read -r w h < <(
        xrandr --current 2>/dev/null |
            sed -n 's/.*current \([0-9]\+\) x \([0-9]\+\).*/\1 \2/p'
    ); then
        [[ -n ${w:-} && -n ${h:-} ]] && screen_w=$w screen_h=$h
    fi
fi

x_offset=$(((screen_w - menu_w - margin_x) - (screen_w - menu_w) / 2))
y_offset=$((bar_h + margin_y - (screen_h - menu_h) / 2))

theme=$(
    cat <<EOF
window {
    width: ${menu_w}px;
    height: ${menu_h}px;
    location: "center";
    anchor: "center";
    x-offset: ${x_offset}px;
    y-offset: ${y_offset}px;
    border: 2px;
    border-color: @selected-normal-background;
    border-radius: 10px;
    padding: 8px;
}
mainbox {
    padding: 0;
    spacing: 4px;
}
inputbar {
    enabled: false;
}
listview {
    lines: 3;
    columns: 1;
    spacing: 4px;
    dynamic: false;
    scrollbar: false;
}
element {
    padding: 8px 12px;
    border-radius: 6px;
}
element selected {
    background-color: @selected-normal-background;
    text-color: @selected-normal-foreground;
}
EOF
)

choice=$(printf '%s\n' "Uitzetten" "Opnieuw opstarten" "Uitloggen" |
    rofi -dmenu -no-custom -i -p "" -theme-str "$theme")

# Escape, klik buiten het menu of een lege keuze: niets doen.
[[ -z ${choice} ]] && exit 0

case "${choice}" in
    "Uitzetten")
        systemctl poweroff
        ;;
    "Opnieuw opstarten")
        systemctl reboot
        ;;
    "Uitloggen")
        # Laat qtile netjes stoppen (beëindigt de X-sessie). Lukt dat niet,
        # beëindig dan de logind-sessie direct.
        qtile cmd-obj -o cmd -f shutdown >/dev/null 2>&1 ||
            loginctl terminate-session "${XDG_SESSION_ID}"
        ;;
esac

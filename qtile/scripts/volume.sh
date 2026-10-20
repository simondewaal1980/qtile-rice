#!/usr/bin/env bash
#
# volume.sh — volume van de standaardsink aanpassen of dempen.
#
# Gebruik: volume.sh up|down|mute|mic-mute

set -u

action=${1:-}
case "$action" in
    up|down|mute|mic-mute) ;;
    *)
        echo "Gebruik: $0 up|down|mute|mic-mute" >&2
        exit 2
        ;;
esac

command -v pactl >/dev/null 2>&1 || exit 1

notify() {
    local summary=$1 message=$2 percent=${3:-}
    command -v notify-send >/dev/null 2>&1 || return 0
    if [[ -n $percent ]]; then
        notify-send -h string:x-dunst-stack-tag:volume \
            -h "int:value:$percent" "$summary" "$message"
    else
        notify-send -h string:x-dunst-stack-tag:volume "$summary" "$message"
    fi
}

case "$action" in
    up)
        pactl set-sink-volume @DEFAULT_SINK@ +5% >/dev/null || exit 1
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -5% >/dev/null || exit 1
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null || exit 1
        ;;
    mic-mute)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle >/dev/null || exit 1
        ;;
esac

if [[ $action == mic-mute ]]; then
    muted=$(LC_ALL=C pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{ print $2 }')
    if [[ $muted == yes ]]; then
        notify "Microfoon" "Gedempt"
    else
        notify "Microfoon" "Ingeschakeld"
    fi
    exit 0
fi

muted=$(LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{ print $2 }')
if [[ $muted == yes ]]; then
    notify "Volume" "Gedempt"
    exit 0
fi

percent=$(
    LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
        grep -oE '[0-9]+%' |
        head -n 1 |
        tr -d '%'
)
if [[ -n $percent ]]; then
    ((percent > 100)) && percent=100
    notify "Volume" "${percent}%" "$percent"
else
    notify "Volume" "Aangepast"
fi

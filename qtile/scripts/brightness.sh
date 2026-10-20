#!/usr/bin/env bash
#
# brightness.sh — helderheid van het beeldscherm aanpassen.
#
# Gebruik: brightness.sh up|down
#
# Eerst via systemd-logind (SetBrightness); een actieve lokale sessie mag dat
# zonder root. Lukt dat niet, dan proberen we brightnessctl, sysfs en tot slot
# xrandr (softwaredimming).

set -u

direction=${1:-}
case "$direction" in
    up|down) ;;
    *)
        echo "Gebruik: $0 up|down" >&2
        exit 2
        ;;
esac

step_percent=5

notify() {
    local percent=${1:-}
    command -v notify-send >/dev/null 2>&1 || return 0
    if [[ $percent =~ ^[0-9]+$ ]]; then
        notify-send -h string:x-dunst-stack-tag:brightness \
            -h "int:value:$percent" "Helderheid" "${percent}%"
    else
        notify-send -h string:x-dunst-stack-tag:brightness "Helderheid" "Aangepast"
    fi
}

session_id() {
    if [[ -n ${XDG_SESSION_ID:-} ]]; then
        printf '%s\n' "$XDG_SESSION_ID"
        return 0
    fi
    command -v loginctl >/dev/null 2>&1 || return 1
    loginctl list-sessions --no-legend 2>/dev/null |
        awk -v user="$USER" '$3 == user { print $1; exit }'
}

# systemd-logind: org.freedesktop.login1.Session.SetBrightness
apply_logind() {
    command -v gdbus >/dev/null 2>&1 || return 1
    local sid session_path dir name max cur step new percent
    sid=$(session_id) || return 1
    [[ -n $sid ]] || return 1

    session_path=$(
        gdbus call --system --dest org.freedesktop.login1 \
            --object-path /org/freedesktop/login1 \
            --method org.freedesktop.login1.Manager.GetSession "$sid" 2>/dev/null |
            sed -n "s/.*'\(.*\)'.*/\1/p"
    )
    [[ -n $session_path ]] || return 1

    for dir in /sys/class/backlight/*; do
        [[ -d $dir ]] || continue
        name=$(basename "$dir")
        [[ -r $dir/brightness && -r $dir/max_brightness ]] || continue
        max=$(<"$dir/max_brightness")
        cur=$(<"$dir/brightness")
        [[ $max -gt 0 ]] || continue
        step=$((max * step_percent / 100))
        ((step < 1)) && step=1
        if [[ $direction == up ]]; then
            new=$((cur + step))
        else
            new=$((cur - step))
        fi
        ((new > max)) && new=$max
        ((new < 1)) && new=1
        percent=$((new * 100 / max))
        if gdbus call --system --dest org.freedesktop.login1 \
            --object-path "$session_path" \
            --method org.freedesktop.login1.Session.SetBrightness \
            backlight "$name" "$new" >/dev/null 2>&1; then
            notify "$percent"
            return 0
        fi
    done
    return 1
}

apply_brightnessctl() {
    command -v brightnessctl >/dev/null 2>&1 || return 1
    local percent
    if [[ $direction == up ]]; then
        brightnessctl set "${step_percent}%+" >/dev/null 2>&1 || return 1
    else
        brightnessctl set "${step_percent}%-" >/dev/null 2>&1 || return 1
    fi
    percent=$(brightnessctl -m 2>/dev/null | awk -F, '{ print $4 }' | tr -d '%')
    notify "$percent"
    return 0
}

apply_sysfs() {
    local dir max cur step new percent
    for dir in /sys/class/backlight/*; do
        [[ -d $dir ]] || continue
        [[ -r $dir/brightness && -r $dir/max_brightness ]] || continue
        max=$(<"$dir/max_brightness")
        cur=$(<"$dir/brightness")
        [[ $max -gt 0 ]] || continue
        step=$((max * step_percent / 100))
        ((step < 1)) && step=1
        if [[ $direction == up ]]; then
            new=$((cur + step))
        else
            new=$((cur - step))
        fi
        ((new > max)) && new=$max
        ((new < 1)) && new=1
        percent=$((new * 100 / max))
        if printf '%s\n' "$new" > "$dir/brightness" 2>/dev/null; then
            notify "$percent"
            return 0
        fi
    done
    return 1
}

apply_xrandr() {
    command -v xrandr >/dev/null 2>&1 || return 1
    local output current new percent state_dir state_file
    output=$(
        xrandr --query 2>/dev/null |
            awk '/ connected primary / { print $1; exit }'
    )
    if [[ -z $output ]]; then
        output=$(
            xrandr --query 2>/dev/null |
                awk '/ connected / { print $1; exit }'
        )
    fi
    [[ -n $output ]] || return 1

    # xrandr kan de ingestelde gamma niet teruglezen; houd de stand bij.
    state_dir=${XDG_CACHE_HOME:-$HOME/.cache}/qtile
    state_file=$state_dir/brightness
    mkdir -p "$state_dir" 2>/dev/null || return 1
    current=$(cat "$state_file" 2>/dev/null || printf '1.0')
    new=$(
        awk -v c="$current" -v d="$direction" 'BEGIN {
            step = 0.05
            if (d == "up") c += step
            else c -= step
            if (c < 0.10) c = 0.10
            if (c > 1.00) c = 1.00
            printf "%.2f", c
        }'
    )
    xrandr --output "$output" --brightness "$new" >/dev/null 2>&1 || return 1
    printf '%s\n' "$new" > "$state_file"
    percent=$(awk -v c="$new" 'BEGIN { printf "%d", c * 100 }')
    notify "$percent"
    return 0
}

if apply_logind || apply_brightnessctl || apply_sysfs || apply_xrandr; then
    exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send -h string:x-dunst-stack-tag:brightness \
        "Helderheid" "Kon de helderheid niet aanpassen"
fi
exit 1

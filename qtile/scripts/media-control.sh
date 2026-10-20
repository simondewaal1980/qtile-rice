#!/usr/bin/env bash
#
# media-control.sh — mediatoetsen voor de actieve MPRIS-speler.
#
# Gebruik: media-control.sh play-pause|next|previous|stop
#
# Gebruikt playerctl als dat geïnstalleerd is; anders rechtstreeks MPRIS via
# gdbus. Zo werken de mediatoetsen ook zonder extra pakketten.

set -u

action=${1:-play-pause}
case "$action" in
    play-pause)
        playerctl_action=play-pause
        mpris_method=PlayPause
        ;;
    next)
        playerctl_action=next
        mpris_method=Next
        ;;
    previous)
        playerctl_action=previous
        mpris_method=Previous
        ;;
    stop)
        playerctl_action=stop
        mpris_method=Stop
        ;;
    *)
        echo "Gebruik: $0 play-pause|next|previous|stop" >&2
        exit 2
        ;;
esac

if command -v playerctl >/dev/null 2>&1; then
    playerctl "$playerctl_action" >/dev/null 2>&1 && exit 0
    # Geen speler of geen playerctl-support: probeer alsnog MPRIS.
fi

command -v gdbus >/dev/null 2>&1 || exit 1

names=$(
    gdbus call --session --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.ListNames 2>/dev/null |
        grep -oE 'org\.mpris\.MediaPlayer2\.[A-Za-z0-9_.-]+' |
        grep -v '^org\.mpris\.MediaPlayer2\.playerctld$' |
        sort -u
)

[[ -n $names ]] || exit 0

# Kies de speler die op dit moment afspeelt; anders de eerste die reageert.
chosen=
while IFS= read -r name; do
    status=$(
        gdbus call --session --dest "$name" \
            --object-path /org/mpris/MediaPlayer2 \
            --method org.freedesktop.DBus.Properties.Get \
            org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null
    )
    case "$status" in
        *Playing*)
            chosen=$name
            break
            ;;
    esac
    [[ -z $chosen ]] && chosen=$name
done <<< "$names"

[[ -n $chosen ]] || exit 0

# Stuur de opdracht; reageert de gekozen speler niet, probeer dan de rest.
for name in "$chosen" $names; do
    if gdbus call --session --dest "$name" \
        --object-path /org/mpris/MediaPlayer2 \
        --method "org.mpris.MediaPlayer2.Player.$mpris_method" >/dev/null 2>&1; then
        exit 0
    fi
done

exit 1

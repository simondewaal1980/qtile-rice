#!/usr/bin/env bash
#
# lock.sh — vergrendel de sessie.
#
# Xscreensaver is standaard aanwezig; de daemon start via de autostart in
# config.py. Is hij toch niet actief, dan start dit script hem alsnog.

set -u

if command -v xscreensaver-command >/dev/null 2>&1; then
    if ! pgrep -x xscreensaver >/dev/null 2>&1 &&
        command -v xscreensaver >/dev/null 2>&1; then
        xscreensaver -no-splash >/dev/null 2>&1 &
        sleep 0.5
    fi
    if xscreensaver-command -quiet -lock >/dev/null 2>&1; then
        exit 0
    fi
fi

# Laatst bekende terugvaloptie: vraag systemd-logind de sessie te vergrendelen.
if command -v loginctl >/dev/null 2>&1 && [[ -n ${XDG_SESSION_ID:-} ]]; then
    loginctl lock-session "$XDG_SESSION_ID" >/dev/null 2>&1 && exit 0
fi

exit 1

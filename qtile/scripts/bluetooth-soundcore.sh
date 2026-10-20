#!/usr/bin/env bash
# Houdt de soundcore Space One Pro (Bluetooth) automatisch verbonden en zet
# het geluid naar de koptelefoon bij elke nieuwe verbinding.
#
# Wordt gestart vanuit de qtile-autostart (config.py, startup_once).
# Aanpak: poll elke 15 s of het apparaat verbonden is; zo niet, probeer te
# verbinden (met timeout, want bluetoothctl kan lang wachten). Lukt een nieuwe
# verbinding, dan wordt de PipeWire-sink van de koptelefoon de standaard-
# uitvoer en verhuizen bestaande audiostreams mee.

set -u

MAC="7C:E9:13:93:7A:2A"

# In de PipeWire-sinknaam staat het MAC-adres, bijv.:
#   bluez_output.7C:E9:13:93:7A:2A
# (kleine letters zodat we hoofdletterongevoelig kunnen matchen)
SINK_PATTERN="7c:e9:13:93:7a:2a"

is_connected() {
    bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"
}

# Wacht tot PipeWire de bluetooth-sink heeft aangemaakt en maak die dan
# de standaarduitvoer (bestaande streams verhuizen mee).
use_as_default_sink() {
    local sink input_id
    for _ in $(seq 1 15); do
        sink=$(pactl list short sinks 2>/dev/null |
            awk -v pat="$SINK_PATTERN" 'tolower($0) ~ pat { print $2; exit }')
        if [ -n "${sink:-}" ]; then
            pactl set-default-sink "$sink" 2>/dev/null
            while read -r input_id; do
                pactl move-sink-input "$input_id" "$sink" 2>/dev/null
            done < <(pactl list short sink-inputs 2>/dev/null | cut -f1)
            return 0
        fi
        sleep 1
    done
    return 1
}

# Al verbonden bij het starten van de sessie (koptelefoon stond al aan)?
# Dan meteen het geluid erheen sturen.
if is_connected; then
    use_as_default_sink
fi

# Blijven waken: staat de koptelefoon uit en later weer aan, dan verbinden we
# opnieuw; bij een nieuwe verbinding gaat het geluid naar de koptelefoon.
while true; do
    if ! is_connected; then
        # timeout: bluetoothctl blijft soms lang hangen als het apparaat uit is.
        if timeout 30 bluetoothctl connect "$MAC" >/dev/null 2>&1; then
            use_as_default_sink
        fi
    fi
    sleep 15
done

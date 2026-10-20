#!/usr/bin/env bash
#
# install.sh — zet de configuratie uit deze repo op hun plek in ~/.config.
#
# Gebruik:
#   ./install.sh              kopieer alle configuraties
#   ./install.sh --packages   installeer ook de benodigde pakketten
#                             (Arch: pacman/AUR, Ubuntu: apt/pipx)
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

install_packages=false
[[ "${1:-}" == "--packages" ]] && install_packages=true

if ${install_packages}; then
    if command -v pacman >/dev/null 2>&1; then
        echo ">> Pakketten installeren (Arch/pacman)…"
        sudo pacman -S --needed --noconfirm \
            qtile rofi kitty picom dunst feh imagemagick xorg-xrdb \
            ttf-font-awesome git base-devel python-setuptools

        if ! pacman -Q python-pywal16 >/dev/null 2>&1; then
            echo ">> python-pywal16 uit de AUR bouwen…"
            tmp="$(mktemp -d)"
            git clone https://aur.archlinux.org/python-pywal16.git "${tmp}/python-pywal16"
            ( cd "${tmp}/python-pywal16" && makepkg -si --noconfirm )
            rm -rf "${tmp}"
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        echo ">> Pakketten installeren (Ubuntu/apt)…"
        sudo apt-get update
        sudo apt-get install -y \
            qtile rofi kitty picom dunst feh imagemagick x11-xserver-utils \
            fonts-font-awesome python3 python3-pip pipx git build-essential \
            python3-setuptools libnotify-bin pulseaudio-utils bluez blueman \
            pavucontrol libglib2.0-bin procps curl

        if ! command -v wal >/dev/null 2>&1; then
            echo ">> pywal16 via pipx installeren…"
            if ! pipx install pywal16; then
                pipx upgrade pywal16 || true
            fi
        fi
        # pipx installeert 'wal' in ~/.local/bin; meteen bruikbaar in dit script.
        export PATH="${HOME}/.local/bin:${PATH}"
    else
        echo "!! Onbekende packagebeheerder. Installeer de pakketten handmatig" >&2
        echo "   volgens packages/pacman.txt of packages/apt.txt." >&2
        exit 1
    fi
fi

echo ">> Configuraties kopiëren naar ${CONFIG_DIR}…"
mkdir -p "${CONFIG_DIR}/qtile/scripts" "${CONFIG_DIR}/picom" \
         "${CONFIG_DIR}/rofi" "${CONFIG_DIR}/kitty" \
         "${CONFIG_DIR}/opencode" "${CONFIG_DIR}/wal/colorschemes/dark" \
         "${CONFIG_DIR}/wal/templates"

install -m 644 "${REPO_DIR}/qtile/config.py"          "${CONFIG_DIR}/qtile/config.py"
install -m 755 "${REPO_DIR}/qtile/scripts/"*.sh       "${CONFIG_DIR}/qtile/scripts/"
install -m 644 "${REPO_DIR}/picom/picom.conf"         "${CONFIG_DIR}/picom/picom.conf"
install -m 644 "${REPO_DIR}/rofi/config.rasi"         "${CONFIG_DIR}/rofi/config.rasi"
install -m 644 "${REPO_DIR}/kitty/kitty.conf"         "${CONFIG_DIR}/kitty/kitty.conf"
install -m 644 "${REPO_DIR}/opencode/cli.json"        "${CONFIG_DIR}/opencode/cli.json"

# pywal: colorschemes (o.a. 'current') en eventuele eigen templates.
if compgen -G "${REPO_DIR}/wal/colorschemes/dark/*.json" >/dev/null; then
    install -m 644 "${REPO_DIR}/wal/colorschemes/dark/"*.json \
        "${CONFIG_DIR}/wal/colorschemes/dark/"
fi
if compgen -G "${REPO_DIR}/wal/templates/*" >/dev/null; then
    install -m 644 "${REPO_DIR}/wal/templates/"* "${CONFIG_DIR}/wal/templates/"
fi

# systemd-user-timer die de wallpaper elke 10 minuten wisselt.
mkdir -p "${CONFIG_DIR}/systemd/user"
install -m 644 "${REPO_DIR}/systemd/"*.service "${REPO_DIR}/systemd/"*.timer \
    "${CONFIG_DIR}/systemd/user/"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now wallpaper-rotate.timer 2>/dev/null \
        && echo ">> Timer 'wallpaper-rotate.timer' geactiveerd (elke 10 minuten)."
fi

if ! find "${HOME}/.local/share/wallpapers" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print -quit 2>/dev/null | grep -q .; then
    echo "!! Geen wallpapers gevonden in ~/.local/share/wallpapers."
    echo "   Haal de voorbeeldset op met: ./wallpapers/fetch-greek-wallpapers.sh"
fi

if command -v wal >/dev/null 2>&1; then
    echo ">> Kleurenschema genereren en toepassen…"
    "${CONFIG_DIR}/qtile/scripts/set-wallpaper.sh" || true
else
    echo "!! 'wal' (pywal16) niet gevonden. Installeer met: ./install.sh --packages"
    echo "   Op Ubuntu: pipx install pywal16 (daarna opnieuw inloggen of"
    echo "   ~/.local/bin aan je PATH toevoegen)."
fi

echo ">> Klaar. Herstart qtile (mod+ctrl+q gevolgd door opnieuw inloggen) om alles te laden."

#!/usr/bin/env bash
#
# install.sh — zet de configuratie uit deze repo op hun plek in ~/.config.
#
# Gebruik:
#   ./install.sh              kopieer alle configuraties
#   ./install.sh --packages   installeer ook de benodigde pakketten (pacman + AUR)
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

install_packages=false
[[ "${1:-}" == "--packages" ]] && install_packages=true

if ${install_packages}; then
    echo ">> Pakketten installeren (officiële repo's)…"
    sudo pacman -S --needed --noconfirm \
        picom feh imagemagick xorg-xrdb git base-devel python-setuptools

    if ! pacman -Q python-pywal16 >/dev/null 2>&1; then
        echo ">> python-pywal16 uit de AUR bouwen…"
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/python-pywal16.git "${tmp}/python-pywal16"
        ( cd "${tmp}/python-pywal16" && makepkg -si --noconfirm )
        rm -rf "${tmp}"
    fi
fi

echo ">> Configuraties kopiëren naar ${CONFIG_DIR}…"
mkdir -p "${CONFIG_DIR}/qtile/scripts" "${CONFIG_DIR}/picom" \
         "${CONFIG_DIR}/rofi" "${CONFIG_DIR}/alacritty"

install -m 644 "${REPO_DIR}/qtile/config.py"          "${CONFIG_DIR}/qtile/config.py"
install -m 755 "${REPO_DIR}/qtile/scripts/"*.sh       "${CONFIG_DIR}/qtile/scripts/"
install -m 644 "${REPO_DIR}/picom/picom.conf"         "${CONFIG_DIR}/picom/picom.conf"
install -m 644 "${REPO_DIR}/rofi/config.rasi"         "${CONFIG_DIR}/rofi/config.rasi"
install -m 644 "${REPO_DIR}/alacritty/alacritty.toml" "${CONFIG_DIR}/alacritty/alacritty.toml"

if command -v wal >/dev/null 2>&1; then
    echo ">> Kleurenschema genereren en toepassen…"
    "${CONFIG_DIR}/qtile/scripts/set-wallpaper.sh" || true
else
    echo "!! 'wal' (pywal16) niet gevonden. Installeer met: ./install.sh --packages"
fi

echo ">> Klaar. Herstart qtile (mod+ctrl+q gevolgd door opnieuw inloggen) om alles te laden."

#!/usr/bin/env bash
#
# sync.sh — werk deze repo bij vanuit de live-configuratie in ~/.config.
#
# Gebruik:
#   ./sync.sh                  kopieer live-configs naar de repo en toon de wijzigingen
#   ./sync.sh -m "boodschap"   idem, en maak meteen een commit
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

commit_msg=""
while getopts ":m:h" opt; do
    case "${opt}" in
        m) commit_msg="${OPTARG}" ;;
        h|*) echo "Gebruik: $0 [-m \"commit-boodschap\"]" >&2; exit 2 ;;
    esac
done

shopt -s nullglob

copy() {
    local src="$1" dst="$2" mode=644
    if [[ ! -e "${src}" ]]; then
        echo "!! ontbreekt, overgeslagen: ${src}" >&2
        return 0
    fi
    if [[ -x "${src}" ]]; then mode=755; fi
    mkdir -p "$(dirname "${dst}")"
    install -m "${mode}" "${src}" "${dst}"
}

copy "${CONFIG_DIR}/qtile/config.py"           "${REPO_DIR}/qtile/config.py"
for s in "${CONFIG_DIR}/qtile/scripts/"*.sh; do
    copy "${s}" "${REPO_DIR}/qtile/scripts/$(basename "${s}")"
done
copy "${CONFIG_DIR}/picom/picom.conf"          "${REPO_DIR}/picom/picom.conf"
copy "${CONFIG_DIR}/rofi/config.rasi"          "${REPO_DIR}/rofi/config.rasi"
copy "${CONFIG_DIR}/kitty/kitty.conf"          "${REPO_DIR}/kitty/kitty.conf"
copy "${CONFIG_DIR}/alacritty/alacritty.toml"  "${REPO_DIR}/alacritty/alacritty.toml"
copy "${CONFIG_DIR}/opencode/cli.json"         "${REPO_DIR}/opencode/cli.json"

# pywal-configuratie: colorschemes en templates.
if [[ -d "${CONFIG_DIR}/wal" ]]; then
    mkdir -p "${REPO_DIR}/wal"
    cp -a "${CONFIG_DIR}/wal/." "${REPO_DIR}/wal/"
fi

# Momentopname van het actieve palet, zodat de repo ook zonder cache een
# voorbeeldtheme heeft. Wordt bij elke sync ververst.
WAL_COLORS="${XDG_CACHE_HOME:-${HOME}/.cache}/wal/colors.json"
if [[ -f "${WAL_COLORS}" ]]; then
    mkdir -p "${REPO_DIR}/wal/colorschemes/dark"
    python3 - "${WAL_COLORS}" "${REPO_DIR}/wal/colorschemes/dark/current.json" <<'PY'
"""Bewaar het actieve pywal-palet als colorscheme (wal --theme current)."""
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as fh:
    palette = json.load(fh)

scheme = {"special": palette["special"], "colors": palette["colors"]}
with open(dst, "w", encoding="utf-8") as fh:
    json.dump(scheme, fh, indent=4, ensure_ascii=False)
    fh.write("\n")
PY
fi

cd "${REPO_DIR}"
git add -A

if git diff --cached --quiet; then
    echo ">> Geen wijzigingen: de repo is al up-to-date."
    exit 0
fi

echo ">> Gewijzigde bestanden:"
git --no-pager diff --cached --stat

if [[ -n "${commit_msg}" ]]; then
    git -c core.pager=cat commit -q -m "${commit_msg}"
    echo ">> Commit gemaakt: ${commit_msg}"
else
    echo
    echo ">> Klaargezet (staged). Bekijk met 'git diff --cached' en commit met 'git commit'."
fi

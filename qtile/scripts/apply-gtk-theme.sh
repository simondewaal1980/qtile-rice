#!/usr/bin/env bash
#
# apply-gtk-theme.sh — past het door pywal gegenereerde kleurenschema toe op
#                      GTK3- en GTK4-apps.
#
#   * schrijft ~/.cache/wal/gtk-colors.css (de kleuren)
#   * laat ~/.config/gtk-{3,4}.0/gtk.css dat bestand importeren
#   * zet GTK3 op de donkere variant en kleurschema 'prefer-dark'
#
# Wordt automatisch aangeroepen door set-wallpaper.sh.
#
set -euo pipefail

WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
COLORS_SH="${WAL_CACHE}/colors.sh"

if [[ ! -f "${COLORS_SH}" ]]; then
    echo "apply-gtk-theme: ${COLORS_SH} ontbreekt (draai eerst 'wal')." >&2
    exit 1
fi

# colors.sh verwijst naar $FZF_DEFAULT_OPTS/$LS_COLORS die nog niet bestaan;
# daarom 'set -u' even uitzetten tijdens het inlezen.
# shellcheck disable=SC1090
set +u
source "${COLORS_SH}"   # levert $background, $foreground, $color0..$color15
set -u

gen_css() {
    cat <<EOF
/* Automatisch gegenereerd uit de wallpaper (pywal). Niet handmatig aanpassen. */

@define-color theme_bg_color           ${background};
@define-color theme_fg_color           ${foreground};
@define-color theme_base_color         ${color0};
@define-color theme_text_color         ${foreground};
@define-color theme_selected_bg_color  ${color2};
@define-color theme_selected_fg_color  ${foreground};
@define-color theme_unfocused_bg_color ${background};
@define-color theme_unfocused_fg_color ${color8};
@define-color theme_unfocused_base_color ${color0};
@define-color theme_unfocused_text_color ${color8};
@define-color theme_unfocused_selected_bg_color ${color2};
@define-color theme_unfocused_selected_fg_color ${foreground};
@define-color insensitive_bg_color     ${background};
@define-color insensitive_fg_color     ${color8};
@define-color insensitive_base_color   ${color0};
@define-color borders                  ${color8};
@define-color unfocused_borders        ${color0};
@define-color warning_color            ${color3};
@define-color error_color              ${color1};
@define-color success_color            ${color2};
@define-color accent_color             ${color2};
@define-color accent_bg_color          ${color2};
@define-color accent_fg_color          ${foreground};

window, .background   { background-color: ${background}; color: ${foreground}; }
headerbar, .titlebar  { background-color: ${color0};     color: ${foreground}; }
view, treeview.view   { background-color: ${color0};     color: ${foreground}; }
entry, spinbutton, textview { background-color: ${color0}; color: ${foreground}; }
button                 { background-color: ${color0};     color: ${foreground}; }
button:hover           { background-color: ${color8};     color: ${foreground}; }
menu, .menu, popover   { background-color: ${background}; color: ${foreground}; }
selection, *:selected, *:selected:focus { background-color: ${color2}; color: ${foreground}; }
EOF
}

GTK3_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
mkdir -p "${GTK3_DIR}" "${GTK4_DIR}"

# Kleuren één keer genereren; beide GTK-versies importeren hetzelfde bestand.
gen_css > "${WAL_CACHE}/gtk-colors.css"

for dir in "${GTK3_DIR}" "${GTK4_DIR}"; do
    cat > "${dir}/gtk.css" <<EOF
/* Laadt de kleuren uit de wallpaper. Aanpassen doe je via pywal, niet hier. */
@import url("file://${WAL_CACHE}/gtk-colors.css");
EOF
done

# GTK3: standaard de donkere variant van het thema gebruiken.
GTK3_SETTINGS="${GTK3_DIR}/settings.ini"
if [[ ! -f "${GTK3_SETTINGS}" ]]; then
    printf '[Settings]\ngtk-application-prefer-dark-theme=1\n' > "${GTK3_SETTINGS}"
elif ! grep -q '^gtk-application-prefer-dark-theme' "${GTK3_SETTINGS}"; then
    printf '\ngtk-application-prefer-dark-theme=1\n' >> "${GTK3_SETTINGS}"
fi

# Kleurschema 'prefer-dark' zodat ook libadwaita-apps (GNOME/GTK4) donker zijn.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi

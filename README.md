# Qtile rice

Een complete, samenhangende desktop-opzet voor **Arch Linux + qtile (X11)**, waarbij
het kleurenschema automatisch uit de wallpaper wordt gegenereerd en doorwerkt op
qtile, rofi, de terminal en GTK-apps.

## Onderdelen

| Map | Doel |
|---|---|
| `qtile/` | qtile-configuratie (`config.py`) + hulpscripts |
| `picom/` | compositor (schaduwen, transparantie, afgeronde hoeken, blur) |
| `rofi/` | applicatielauncher (kleuren via pywal) |
| `alacritty/` | terminal (kleuren via pywal) |
| `packages/` | lijst met benodigde pakketten (officiële repo's + AUR) |

## Hoe de theming werkt

De wallpaper is de bron van het kleurenschema (via [pywal16](https://github.com/eylles/pywal16)):

```
wal -i <wallpaper> -n        →  palet in ~/.cache/wal/
├── xrdb -merge              →  X-apps (xterm, urxvt, …)          ~/.cache/wal/colors.Xresources
├── apply-gtk-theme.sh       →  GTK3 + GTK4 + gsettings prefer-dark
└── qtile reload_config      →  balk, vensterranden, rofi, alacritty
```

- `qtile/scripts/set-wallpaper.sh` — genereert het schema en past alles toe.
- `qtile/scripts/apply-gtk-theme.sh` — schrijft `~/.cache/wal/gtk-colors.css` en laat
  `~/.config/gtk-{3,4}.0/gtk.css` dat importeren; zet `prefer-dark`.
- `qtile/scripts/wallpaper-pick.sh` — rofi-galerij met thumbnails om een wallpaper te kiezen.
- qtile tekent de achtergrond zelf (`wallpaper=` in `config.py`), daarom gebruikt
  pywal de optie `-n` (zet de wallpaper niet zelf).

## Sneltoetsen (relevante)

| Toets | Actie |
|---|---|
| `mod+shift+w` | Wallpaper kiezen (galerij) → nieuw kleurenschema |
| `mod+d` | Applicatielauncher (rofi) |
| `mod+Tab` | Vensterkiezer (rofi) |
| `mod+Return` | Terminal (alacritty) |
| `mod+ctrl+r` | qtile-config herladen |

## Installatie

Benodigde software staat in `packages/`. Automatisch installeren + alles op z'n plek zetten:

```bash
./install.sh --packages     # installeert pakketten (pacman + AUR) én kopieert de configs
./install.sh                # alleen de configs kopiëren
```

De pakketten handmatig:

```bash
sudo pacman -S --needed picom feh imagemagick xorg-xrdb git base-devel python-setuptools
# pywal16 uit de AUR:
git clone https://aur.archlinux.org/python-pywal16.git && cd python-pywal16 && makepkg -si
```

Daarna genereert `~/.config/qtile/scripts/set-wallpaper.sh` het schema en start
`picom` automatisch bij de volgende login (via `@hook.subscribe.startup_once` in `config.py`).

## Repo bijwerken vanuit de live-configuratie

Pas je iets aan in `~/.config` en wil je dat in deze repo zetten:

```bash
./sync.sh                  # kopieert live → repo en toont de wijzigingen (staged)
./sync.sh -m "boodschap"   # idem, en maakt meteen een commit
```

`install.sh` doet het omgekeerde: repo → live.

## Aandachtspunten

- **Alacritty**: het importpad in `alacritty/alacritty.toml` is absoluut
  (`/home/<gebruiker>/.cache/wal/colors-alacritty.toml`). Pas dit aan als je een
  andere gebruikersnaam hebt.
- **picom-backend**: `glx` staat aan voor de mooiste resultaten. Op een (virtuele)
  machine zonder goede GL-versnelling: zet in `picom/picom.conf` `backend = "xrender";`
  en `blur-background = false;`.
- **Wallpapers** staan in `~/.local/share/wallpapers/`; pas `WALLPAPER_DIR` in de
  scripts aan als je een andere map wilt.
- GTK4/libadwaita-apps laten zich maar beperkt extern stijlen (beperking van GTK,
  niet van deze opzet); GTK3-apps volgen `gtk.css` volledig.

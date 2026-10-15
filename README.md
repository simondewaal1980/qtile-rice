# Qtile rice

Een complete, samenhangende desktop-opzet voor **Arch Linux + qtile (X11)**, waarbij
het kleurenschema automatisch uit de wallpaper wordt gegenereerd en doorwerkt op
qtile, rofi, de terminal, dunst (notificaties) en GTK-apps.

## Onderdelen

| Map | Doel |
|---|---|
| `qtile/` | qtile-configuratie (`config.py`) + hulpscripts |
| `picom/` | compositor (schaduwen, transparantie, afgeronde hoeken, blur) |
| `rofi/` | applicatielauncher (kleuren via pywal) |
| `alacritty/` | terminal (kleuren via pywal) |
| `systemd/` | systemd-user-timer voor de automatische wallpaperwissel |
| `wallpapers/` | script om een wallpaperset op te halen (Griekse landschappen & stadsgezichten) |
| `packages/` | lijst met benodigde pakketten (officiële repo's + AUR) |

## Hoe de theming werkt

De wallpaper is de bron van het kleurenschema (via [pywal16](https://github.com/eylles/pywal16)):

```
wal -i <wallpaper> -n        →  palet in ~/.cache/wal/
├── xrdb -merge              →  X-apps (xterm, urxvt, …)          ~/.cache/wal/colors.Xresources
├── apply-gtk-theme.sh       →  GTK3 + GTK4 + gsettings prefer-dark
├── dunst-theme.sh           →  notificaties                       ~/.config/dunst/dunstrc
└── qtile reload_config      →  balk, vensterranden, rofi, alacritty
```

- `qtile/scripts/set-wallpaper.sh` — genereert het schema en past alles toe.
- `qtile/scripts/apply-gtk-theme.sh` — schrijft `~/.cache/wal/gtk-colors.css` en laat
  `~/.config/gtk-{3,4}.0/gtk.css` dat importeren; zet `prefer-dark`.
- `qtile/scripts/dunst-theme.sh` — genereert `~/.config/dunst/dunstrc` uit de
  pywal-kleuren en herlaadt een draaiende dunst (`dunstctl reload`). De accentkleur
  (`color2`) is de rand van gewone meldingen, `color1` die van kritieke.
- `qtile/scripts/wallpaper-pick.sh` — rofi-galerij met thumbnails om een wallpaper te kiezen.
- `qtile/scripts/wallpaper-rotate.sh` — kiest een (andere) willekeurige wallpaper en
  werkt het schema bij; aangeroepen door de systemd-timer (zie hieronder).
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

## Automatische wallpaperwissel

Elke **10 minuten** wordt een andere wallpaper uit `~/.local/share/wallpapers/`
gekozen (willekeurig, nooit twee keer achter elkaar dezelfde) en wordt het
pywal-kleurenschema — inclusief dunst — bijgewerkt. Dat draait als
systemd-**user**-timer:

| Bestand | Doel |
|---|---|
| `systemd/wallpaper-rotate.service` | roept `qtile/scripts/wallpaper-rotate.sh` aan |
| `systemd/wallpaper-rotate.timer` | start die service elke 10 minuten (eerste keer 3 min na login) |

Beheren:

```bash
systemctl --user list-timers wallpaper-rotate.timer   # volgende wissel bekijken
systemctl --user stop  wallpaper-rotate.timer         # pauzeren
systemctl --user start wallpaper-rotate.timer         # weer aanzetten
systemctl --user start wallpaper-rotate.service       # nu meteen wisselen
```

`install.sh` zet de units in `~/.config/systemd/user/` en activeert de timer.

## Wallpapers ophalen

`wallpapers/fetch-greek-wallpapers.sh` haalt 20 Griekse landschappen en
stadsgezichten op van [Wikimedia Commons](https://commons.wikimedia.org/) (vrije
licenties) en zet ze in `~/.local/share/wallpapers/`:

```bash
./wallpapers/fetch-greek-wallpapers.sh          # → ~/.local/share/wallpapers/
./wallpapers/fetch-greek-wallpapers.sh ~/mijn   # of een eigen map
```

De afbeeldingen zelf staan **niet** in de repo (samen te groot); het script is
reproduceerbaar. De kiezer (`mod+shift+w`) en de rotatie pikken nieuwe bestanden
automatisch op.

## Installatie

Benodigde software staat in `packages/`. Automatisch installeren + alles op z'n plek zetten:

```bash
./install.sh --packages     # installeert pakketten (pacman + AUR) én kopieert de configs
./install.sh                # alleen de configs kopiëren
```

De pakketten handmatig:

```bash
sudo pacman -S --needed picom dunst feh imagemagick xorg-xrdb git base-devel python-setuptools
# pywal16 uit de AUR:
git clone https://aur.archlinux.org/python-pywal16.git && cd python-pywal16 && makepkg -si
```

Daarna genereert `~/.config/qtile/scripts/set-wallpaper.sh` het schema en het
dunst-thema; bij de volgende login starten `picom` en `dunst` automatisch mee
(via `@hook.subscribe.startup_once` in `config.py`). `install.sh` activeert ook
meteen de timer die elke 10 minuten van wallpaper wisselt.

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
- **Timer & DISPLAY**: de rotatie-service erft `DISPLAY`/`XAUTHORITY` van de
  systemd-user-manager (die ze bij het inloggen meekrijgt). Wisselt er niets?
  Controleer dan of `systemctl --user show-environment` beide variabelen toont.
- GTK4/libadwaita-apps laten zich maar beperkt extern stijlen (beperking van GTK,
  niet van deze opzet); GTK3-apps volgen `gtk.css` volledig.

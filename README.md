# Qtile rice

Een complete, samenhangende desktop-opzet voor **Arch Linux of Ubuntu + qtile (X11)**,
waarbij het kleurenschema automatisch uit de wallpaper wordt gegenereerd en doorwerkt
op qtile, rofi, de terminal, dunst (notificaties), GTK-apps en OpenCode.

De opzet is getest op **Ubuntu 26.04** (qtile 0.34, picom 12.5, rofi 2.0,
kitty 0.45, dunst 1.12) en op Arch Linux. `install.sh --packages` kiest
automatisch tussen pacman/AUR en apt/pipx.

## Onderdelen

| Map | Doel |
|---|---|
| `qtile/` | qtile-configuratie (`config.py`) + hulpscripts |
| `picom/` | compositor (schaduwen, transparantie, afgeronde hoeken, blur) |
| `rofi/` | applicatielauncher (kleuren via pywal) |
| `kitty/` | terminal (kleuren via pywal) |
| `wal/` | pywal16-configuratie + voorbeeldpalet (`current`) |
| `alacritty/` | optionele/oude terminalconfig (wordt niet standaard geïnstalleerd) |
| `opencode/` | OpenCode TUI (thema via pywal) |
| `systemd/` | systemd-user-timer voor de automatische wallpaperwissel |
| `wallpapers/` | script om een wallpaperset op te halen (Griekse landschappen & stadsgezichten) |
| `packages/` | pakketlijsten voor Arch (`pacman.txt` + `aur.txt`) en Ubuntu (`apt.txt`) |
| `docs/` | sneltoetsenoverzicht (Markdown + PDF) en het buildscript |

## Documentatie

- **[Sneltoetsen & begrippen (Markdown)](docs/qtile-sneltoetsen.md)** — alle
  sneltoetsen, muisacties en balkkliks, plus uitleg van de qtile-termen.
- **[Sneltoetsen & begrippen (PDF)](docs/qtile-sneltoetsen.pdf)** — dezelfde
  handleiding als A4-pdf voor offline gebruik. Opnieuw maken met
  `./docs/build-pdf.sh`.

## Hoe de theming werkt

De wallpaper is de bron van het kleurenschema (via [pywal16](https://github.com/eylles/pywal16)):

```
wal -i <wallpaper> -n        →  palet in ~/.cache/wal/
├── xrdb -merge              →  X-apps (xterm, urxvt, …)          ~/.cache/wal/colors.Xresources
├── apply-gtk-theme.sh       →  GTK3 + GTK4 + gsettings prefer-dark
├── apply-kde-theme.sh       →  KDE/Qt-kleurenschema               ~/.local/share/color-schemes/Pywal.colors
├── dunst-theme.sh           →  notificaties                       ~/.config/dunst/dunstrc
├── opencode-theme.sh        →  OpenCode-thema                     ~/.config/opencode/themes/wal.json
└── qtile reload_config      →  balk, vensterranden, rofi, kitty
```

- `qtile/scripts/set-wallpaper.sh` — genereert het schema en past alles toe.
- `qtile/scripts/apply-gtk-theme.sh` — schrijft `~/.cache/wal/gtk-colors.css` en laat
  `~/.config/gtk-{3,4}.0/gtk.css` dat importeren; zet `prefer-dark`.
- `qtile/scripts/apply-kde-theme.sh` — schrijft
  `~/.local/share/color-schemes/Pywal.colors`, activeert dat schema en zet de
  Breeze-widgetstijl, zodat KDE- en Qt-apps het pywal-palet volgen (via
  `QT_QPA_PLATFORMTHEME=kde`).
- `qtile/scripts/dunst-theme.sh` — genereert `~/.config/dunst/dunstrc` uit de
  pywal-kleuren en herlaadt een draaiende dunst (`dunstctl reload`). De accentkleur
  (`color2`) is de rand van gewone meldingen, `color1` die van kritieke.
- `qtile/scripts/opencode-theme.sh` — genereert `~/.config/opencode/themes/wal.json`
  uit het pywal-palet (de `200`-stap van elke kleur is exact de bijbehorende
  pywal-kleur). `~/.config/opencode/cli.json` selecteert het thema
  (`"theme": { "name": "wal", "mode": "dark" }`). Een nieuw thema wordt bij het
  opstarten van OpenCode ingelezen.
- `wal/colorschemes/dark/current.json` — momentopname van het actieve palet.
  Terugzetten kan met `wal --theme current`; `sync.sh` ververst de momentopname.
- `qtile/scripts/wallpaper-pick.sh` — rofi-galerij met thumbnails om een wallpaper te kiezen.
- `qtile/scripts/wallpaper-rotate.sh` — kiest een (andere) willekeurige wallpaper en
  werkt het schema bij; aangeroepen door de systemd-timer (zie hieronder).
- qtile tekent de achtergrond zelf (`wallpaper=` in `config.py`), daarom gebruikt
  pywal de optie `-n` (zet de wallpaper niet zelf).

## Sneltoetsen

Het volledige overzicht staat in
[docs/qtile-sneltoetsen.md](docs/qtile-sneltoetsen.md) (en als
[pdf](docs/qtile-sneltoetsen.pdf)). De belangrijkste:

| Toets | Actie |
|---|---|
| `mod+shift+w` | Wallpaper kiezen (galerij) → nieuw kleurenschema |
| `mod+d` | Applicatielauncher (rofi) |
| `mod+Tab` | Vensterkiezer (rofi) |
| `mod+Return` | Terminal (kitty) |
| `mod+ctrl+r` | qtile-config herladen |
| Klik op de ⏻-knop in de balk | Power-menu: uitzetten, opnieuw opstarten of uitloggen |

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
./install.sh --packages     # kiest pacman/AUR (Arch) of apt/pipx (Ubuntu)
./install.sh                # alleen de configs kopiëren
```

De pakketten handmatig:

```bash
# Arch Linux
sudo pacman -S --needed qtile rofi kitty picom dunst feh imagemagick xorg-xrdb ttf-font-awesome git base-devel python-setuptools
# pywal16 uit de AUR:
git clone https://aur.archlinux.org/python-pywal16.git && cd python-pywal16 && makepkg -si
# of via pipx:
pipx install pywal16

# Ubuntu 26.04
sudo apt update
sudo apt install -y qtile rofi kitty picom dunst feh imagemagick x11-xserver-utils \
  fonts-font-awesome python3 python3-pip pipx git build-essential python3-setuptools \
  libnotify-bin pulseaudio-utils bluez blueman pavucontrol libglib2.0-bin procps curl
pipx install pywal16
```

Op Ubuntu is `xrdb` onderdeel van `x11-xserver-utils` (niet van een los
`xorg-xrdb`-pakket). Zorg dat `~/.local/bin` in je `PATH` staat
(`pipx ensurepath`, daarna opnieuw inloggen), anders vindt het
wallpaper-script `wal` niet.

Daarna genereert `~/.config/qtile/scripts/set-wallpaper.sh` het schema en de
thema's (dunst + OpenCode); bij de volgende login starten `picom` en `dunst` automatisch mee
(via `@hook.subscribe.startup_once` in `config.py`). `install.sh` activeert ook
meteen de timer die elke 10 minuten van wallpaper wisselt.

## Repo bijwerken vanuit de live-configuratie

Pas je iets aan in `~/.config` en wil je dat in deze repo zetten:

```bash
./sync.sh                  # kopieert live → repo en toont de wijzigingen (staged)
./sync.sh -m "boodschap"   # idem, en maakt meteen een commit
```

`sync.sh` neemt ook `kitty/kitty.conf` en de pywal-configuratie mee en ververst
`wal/colorschemes/dark/current.json` met het actieve palet. `install.sh` doet het
omgekeerde: repo → live.

## Aandachtspunten

- **pywal-cache**: kitty importeert `~/.cache/wal/colors-kitty.conf` en rofi
  `~/.cache/wal/colors-rofi-dark.rasi`. Die bestanden ontstaan pas na de eerste
  `wal`-run; `install.sh` draait daarvoor `set-wallpaper.sh`. Ontbreken ze, draai
  dan `~/.config/qtile/scripts/set-wallpaper.sh`.
- **Alacritty** (optioneel): het importpad in `alacritty/alacritty.toml` is absoluut
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
  De service zet `~/.local/bin` expliciet in `PATH`, zodat `wal` uit pipx ook
  buiten een interactieve shell gevonden wordt.
- **Ubuntu**: qtile 0.34 heeft nog geen `Output`-export; `config.py` valt daarop
  terug. Verder zijn de gebruikte opties (`PulseVolume`, `Screen(wallpaper=…)`,
  rofi 2.0-thema's, kitty-include met `~`) op Ubuntu 26.04 getest.
- **Optionele autostart**: `blueman-applet`, de VibeTyper-AppImage en het
  Bluetooth-script worden alleen gestart als ze bestaan. Ontbrekende optionele
  apps blokkeren de rest van de autostart (inclusief de wallpaper) niet meer.
- **pywal op Ubuntu 26.04**: ImageMagick 7 kan tijdens `wal` de melding
  "Imagemagick couldn't generate a palette with magick" geven. pywal probeert
  dan grotere paletten en rondt alsnog af; dit is niet fataal.
- GTK4/libadwaita-apps laten zich maar beperkt extern stijlen (beperking van GTK,
  niet van deze opzet); GTK3-apps volgen `gtk.css` volledig.

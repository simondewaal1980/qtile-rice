# pywal16

Deze map bevat de pywal-configuratie die bij deze rice hoort. De kleuren worden
niet met de hand ingesteld: `qtile/scripts/set-wallpaper.sh` genereert ze uit de
gekozen wallpaper met `wal -i <wallpaper> -n` en schrijft ze naar
`~/.cache/wal/`.

| Pad | Doel |
|---|---|
| `colorschemes/dark/current.json` | momentopname van het actieve palet; terugzetten met `wal --theme current` |
| `templates/` | ruimte voor eigen pywal-templates (de standaardtemplates voor kitty, rofi, enz. zitten al in pywal16) |

## Gebruikte bestanden uit de cache

| Programma | Bestand |
|---|---|
| qtile | `~/.cache/wal/colors.json` (rechtstreeks uitgelezen in `config.py`) |
| kitty | `~/.cache/wal/colors-kitty.conf` |
| rofi | `~/.cache/wal/colors-rofi-dark.rasi` |
| X-apps | `~/.cache/wal/colors.Xresources` |

## Installatie

pywal16 is beschikbaar in de AUR (`python-pywal16`) en via pipx:

```bash
pipx install pywal16     # levert het commando 'wal'
```

Daarna genereert `~/.config/qtile/scripts/set-wallpaper.sh` het schema. De
wallpaperrotatie (`systemd/wallpaper-rotate.timer`) ververst het automatisch
elke 10 minuten.

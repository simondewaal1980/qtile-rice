# Qtile sneltoetsen & begrippen

Een compleet overzicht van alle sneltoetsen, muisacties en balkkliks in deze
qtile-desktop, plus uitleg van de termen die je in qtile en in `config.py`
tegenkomt.

**Omgeving:** qtile 0.34 op Ubuntu 26.04, X11 · **Config:** `~/.config/qtile/config.py`
· **Repo:** [simondewaal1980/qtile-rice](https://github.com/simondewaal1980/qtile-rice)

> **Snel beginnen:** `Super` is de Windows-toets. `Super` + `Return` opent een
> terminal, `Super` + `D` de applicatielauncher en `Super` + `Shift` + `W` de
> wallpaperkiezer. `Super` + `Ctrl` + `R` herlaadt de configuratie.

## Notatie

| Notatie | Betekenis |
|---|---|
| <kbd>Super</kbd> | De Windows-toets. In `config.py` heet deze `mod` of `mod4`. |
| <kbd>Ctrl</kbd> | Control. In `config.py`: `control`. |
| <kbd>Shift</kbd> | Shift. In `config.py`: `shift`. |
| <kbd>Alt</kbd> | Alt. In `config.py`: `mod1`. |
| <kbd>LMB</kbd> / <kbd>RMB</kbd> / <kbd>MMB</kbd> | Linker-, rechter- en middelste muisknop. |
| `+` | Houd de toetsen tegelijk ingedrukt. |

Qtile heeft **geen ingebouwde sneltoetsen**: elke combinatie hieronder komt uit
de lijst `keys` in `config.py`. Verwijder je een regel, dan werkt die toets niet
meer. De standaardsneltoetsen uit de qtile-documentatie zijn hier dus niet
automatisch actief.

## Vensters: focus en beheer

### Focus wisselen

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>H</kbd> | Focus naar het venster links |
| <kbd>Super</kbd> + <kbd>L</kbd> | Focus naar het venster rechts |
| <kbd>Super</kbd> + <kbd>J</kbd> | Focus naar het venster eronder |
| <kbd>Super</kbd> + <kbd>K</kbd> | Focus naar het venster erboven |
| <kbd>Super</kbd> + <kbd>O</kbd> | Volgende venster binnen de layout |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Vensterkiezer openen met rofi |

De richtingtoetsen volgen de **vim-indeling**: `H` links, `J` omlaag, `K`
omhoog, `L` rechts. In Bsp en Columns gaan `H`/`L` tussen vensters of kolommen
en `J`/`K` binnen een kolom. In TreeTab gaan `J`/`K` door de lijst en klappen
`H`/`L` een vertakking in of uit.

### Starten en beheren

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>Return</kbd> | Terminal starten (kitty) |
| <kbd>Super</kbd> + <kbd>D</kbd> | Applicatielauncher openen (rofi) |
| <kbd>Super</kbd> + <kbd>R</kbd> | Commando-prompt in de balk openen |
| <kbd>Super</kbd> + <kbd>W</kbd> | Actief venster sluiten |
| <kbd>Super</kbd> + <kbd>F</kbd> | Volledig scherm aan/uit |
| <kbd>Super</kbd> + <kbd>T</kbd> | Venster zwevend maken of weer tegelen |

> **Let op:** <kbd>Super</kbd> + <kbd>R</kbd> opent qtile's eigen prompt
> (`widget.Prompt`) in de bovenbalk, geen rofi-venster. Typ daar een
> shellcommando en druk op Enter.

## Vensters verplaatsen en formaat wijzigen

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>H</kbd> | Venster naar links verplaatsen |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Venster naar rechts verplaatsen |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>J</kbd> | Venster omlaag verplaatsen |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>K</kbd> | Venster omhoog verplaatsen |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>H</kbd> | Venster naar links laten groeien |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>L</kbd> | Venster naar rechts laten groeien |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>J</kbd> | Venster omlaag laten groeien |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>K</kbd> | Venster omhoog laten groeien |
| <kbd>Super</kbd> + <kbd>N</kbd> | Alle venstergroottes normaliseren |

- **Shuffle** (<kbd>Shift</kbd>) verplaatst een venster naar een andere kolom of
  een andere plek in de stapel. Buiten het bereik van de kolommen maakt qtile
  een nieuwe kolom.
- **Grow** (<kbd>Ctrl</kbd>) vergroot of verkleint de kolom/stapel. Staat het
  venster al tegen de schermrand, dan kan dezelfde toets het juist kleiner maken.
- **Normalize** (<kbd>N</kbd>) zet alle kolommen en stapels terug naar gelijke
  afmetingen.

## Werkplekken

Qtile noemt werkplekken **groups** (groepen). Deze configuratie heeft negen
groepen, met in de balk een Font Awesome-icoon in plaats van het cijfer.

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>1</kbd> … <kbd>9</kbd> | Naar werkplek 1 … 9 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> … <kbd>9</kbd> | Actief venster naar werkplek 1 … 9 verplaatsen én meegaan |

De tweede combinatie gebruikt `togroup(..., switch_group=True)`: het venster
verhuist en je volgt het naar de doelwerkplek. Wil je op de huidige werkplek
blijven, dan verwijder je `switch_group=True` in `config.py`.

| # | Icoon | Bedoeling | Automatisch |
|---|---|---|---|
| 1 | browser | Chrome | `google-chrome-stable` start mee |
| 2 | terminal | Terminal | kitty start mee |
| 3 | map | Bestanden | — |
| 4 | code | Code | — |
| 5 | boek | Documenten | — |
| 6 | afbeelding | Foto's | — |
| 7 | film | Video | — |
| 8 | gamepad | Games | — |
| 9 | Spotify | Muziek | `flatpak run com.spotify.Client` start mee |

Nieuwe vensters worden automatisch aan de juiste groep toegewezen via
`Match(wm_class=...)`: Chrome naar 1, kitty naar 2 en Spotify naar 9. De
`spawn`-opdracht van een groep wordt uitgevoerd wanneer qtile de groep aanmaakt
(bij het opstarten), waardoor die drie apps meteen starten.

## Layouts

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Naar de volgende layout |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Return</kbd> | Splitrichting wisselen (Bsp) / split/unsplit (Columns) |

Deze configuratie gebruikt vier layouts:

1. **Bsp** — bspwm-achtige indeling: elk nieuw venster splitst de ruimte in
   tweeën, afwisselend horizontaal en verticaal. Dit is de standaardlayout.
2. **TreeTab** — vensters staan als boom in een zijpaneel; het actieve venster
   vult de rest van het scherm.
3. **Columns** — kolommen naast elkaar, met per kolom een stapel vensters.
4. **Max** — elk venster vult het hele scherm; alleen het actieve venster is
   zichtbaar.

<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> wisselt tussen deze vier.
In TreeTab verplaats je vensters met <kbd>Super</kbd> + <kbd>Shift</kbd> +
<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd> binnen de boom;
<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>H</kbd>/<kbd>L</kbd> maakt het
zijpaneel smaller of breder. De Columns-specifieke acties (shuffle, grow,
split) hebben in Max geen effect.

## Sessie en systeem

| Sneltoets | Actie |
|---|---|
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>R</kbd> | qtile-configuratie herladen |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Q</kbd> | qtile afsluiten (beëindigt de sessie) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Wallpaper kiezen en kleurenschema aanpassen |
| <kbd>Print</kbd> | Schermafdruk maken met Spectacle |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>F1</kbd> … <kbd>F7</kbd> | Naar virtual terminal 1 … 7 |

De VT-combinatie is in deze config alleen actief onder **Wayland**. Op X11
regelt Xorg de VT-wissel zelf, mits `DontVTSwitch` niet is ingeschakeld.

Druk op <kbd>Print</kbd> om **Spectacle** te openen. Kies daarin een
rechthoekig gebied, het actieve venster of het volledige scherm; daarna kun je
de opname opslaan of naar het klembord kopiëren. Spectacle is de
standaard-schermafdruktool van KDE en staat in `packages/apt.txt` en
`packages/pacman.txt`.

Herladen (<kbd>Ctrl</kbd> + <kbd>R</kbd>) is veilig: je sessie en vensters
blijven bestaan. Afsluiten (<kbd>Ctrl</kbd> + <kbd>Q</kbd>) stopt qtile en
daarmee de X-sessie.

## Mediatoetsen, volume, helderheid en vergrendelen

| Toets | Actie |
|---|---|
| <kbd>Play/Pause</kbd> | Actieve mediaspeler afspelen of pauzeren |
| <kbd>Volgende</kbd> / <kbd>Vorige</kbd> | Volgende of vorige track |
| <kbd>Volume +</kbd> / <kbd>Volume −</kbd> | Volume met 5% aanpassen |
| <kbd>Mute</kbd> | Geluid dempen of weer aanzetten |
| <kbd>Mic mute</kbd> | Microfoon dempen of weer aanzetten |
| <kbd>Helderheid +</kbd> / <kbd>Helderheid −</kbd> | Schermhelderheid met 5% aanpassen |
| <kbd>Super</kbd> + <kbd>Esc</kbd> of <kbd>Screen lock</kbd> | Scherm vergrendelen |

De mediatoetsen werken via **MPRIS**: `media-control.sh` gebruikt `playerctl`
als dat geïnstalleerd is en praat anders rechtstreeks met de speler via
`gdbus`. Volume gaat via `pactl` (PulseAudio of PipeWire). Helderheid gaat via
`systemd-logind`, zodat een actieve lokale sessie geen root nodig heeft; als
dat niet lukt, volgt een terugval op `brightnessctl`, sysfs of `xrandr`.
Vergrendelen doet `lock.sh` met **xscreensaver**, dat via de autostart meedraait.

## Muis

| Actie | Resultaat |
|---|---|
| <kbd>Super</kbd> + <kbd>LMB</kbd> slepen | Zwevend venster verplaatsen |
| <kbd>Super</kbd> + <kbd>RMB</kbd> slepen | Zwevend venster van formaat veranderen |
| <kbd>Super</kbd> + <kbd>MMB</kbd> klikken | Zwevend venster naar voren halen |

Deze muisacties werken alleen bij **zwevende** vensters. Een getegeld venster
verplaats of vergroot je met de toetsenbordcombinaties hierboven.

`follow_mouse_focus = True` betekent dat de focus de muis volgt: beweeg je naar
een venster, dan wordt het actief. `cursor_warp = False` zorgt ervoor dat de
cursor niet naar een venster springt wanneer je met het toetsenbord van focus
wisselt.

## Menu's en prompts

| Menu | Openen | Bediening |
|---|---|---|
| Applicatielauncher | <kbd>Super</kbd> + <kbd>D</kbd> | Typ om te zoeken, pijltjes om te kiezen, Enter, Esc om te sluiten |
| Vensterkiezer | <kbd>Super</kbd> + <kbd>Tab</kbd> | Typ om te filteren, Enter om te wisselen |
| Wallpapergalerij | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Pijltjes, Enter om te kiezen, Esc om te annuleren |
| Power-menu | Linksklik op de ⏻-knop | Eén klik op een optie voert die direct uit; Esc of klik buiten sluit |
| Commando-prompt | <kbd>Super</kbd> + <kbd>R</kbd> | Commando typen, Enter; Esc annuleert |

Het power-menu gebruikt rofi met `-hover-select` en
`-me-accept-entry MousePrimary`, waardoor één muisklik op een optie genoeg is.
De opties zijn **Vergrendelen**, **Uitzetten**, **Opnieuw opstarten** en
**Uitloggen**. Het wallpaper-menu toont thumbnails en werkt het
pywal-kleurenschema bij zodra je een keuze maakt.

## De bovenbalk

De balk is 44 pixels hoog en wordt door qtile zelf getekend. Van links naar
rechts staan deze widgets:

| Onderdeel | Betekenis | Muisactie |
|---|---|---|
| Layout-icoon | Huidige layout (TreeTab, Bsp, Columns of Max) | — |
| Werkplekken | De negen groepen als icoon | Klik op een icoon om te wisselen |
| Prompt | Verschijnt bij <kbd>Super</kbd> + <kbd>R</kbd> | Typ een commando, Enter om uit te voeren |
| Vensternaam | Titel van het actieve venster | — |
| Weer | Actueel weer voor Eindhoven, elke 15 minuten | Rechtsklik opent wttr.in |
| Accu | Percentage en oplaadstatus, elke 30 seconden | — |
| Volume | Luidspreker en mute-status | Linksklik: `pavucontrol` · rechtsklik: dempen · scrollen: volume |
| Systray | Icoontjes van achtergrondapps (blueman, Vibe Typer) | Normale app-acties |
| Klok | Datum en tijd | — |
| Power | Aan/uit-knop | Linksklik opent het power-menu |

De weerwidget gebruikt `wttr.in` en heeft geen API-sleutel nodig. Onder de 15%
accu wordt het percentage rood. De groepsiconen en enkele balkiconen zijn
Font Awesome-glyphs; zonder dat font verschijnen er vierkantjes.

## Wat is hier niet ingesteld?

Deze configuratie heeft **geen** sneltoetsen voor:

- mediatoetsen (play/pause, volgende/vorige);
- volume- of helderheidstoetsen;
- scherm vergrendelen;
- vensters naar een specifieke hoek of monitor sturen;
- een idle-timer of automatische lock (de lijsten `idle_timers` en
  `idle_inhibitors` zijn leeg).

Die kun je zelf toevoegen met een `Key(...)`-regel in de lijst `keys` in
`~/.config/qtile/config.py`, liefst naast de andere `spawn`-sneltoetsen.
Herlaad daarna met <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>R</kbd>. Is het
programma niet geïnstalleerd, dan gebeurt er niets.

## Qtile-begrippen

### De basis

**Qtile** — een tiling window manager geschreven in Python. De configuratie is
echte Python-code, geen tekstformaat zoals bij i3. Daardoor kun je lussen,
voorwaarden en imports gebruiken. Qtile regelt vensters, layouts en de balk; het
is geen complete desktopomgeving zoals Plasma.

**Window manager (WM)** — het programma dat bepaalt waar vensters staan, welke
focus hebben, hoe je ze verplaatst en welke sneltoetsen gelden. In deze opzet
vervangt qtile KWin/Plasma.

**Tiling** — vensters worden automatisch naast en onder elkaar geplaatst en
vullen het scherm zonder overlap. De tegenhanger is floating.

**Floating** — een venster zweeft vrij boven de getegelde vensters en heeft een
eigen positie en grootte. Dialogen, `pinentry`, `ssh-askpass` en gitk-vensters
krijgen dat automatisch via `float_rules`; met <kbd>Super</kbd> + <kbd>T</kbd>
maak je elk venster handmatig zwevend.

**mod / mod4 / Super** — `mod = "mod4"` verwijst naar de Windows-toets. `mod1`
is Alt, `control` is Ctrl en `shift` is Shift. `mod` is een afspraak in de
configuratie, geen aparte toets.

**Key** — een object in de lijst `keys` dat een toetscombinatie aan een actie
koppelt, bijvoorbeeld `Key([mod, "shift"], "h", lazy.layout.shuffle_left())`.
De optionele `desc` is een leesbare omschrijving van de actie.

**lazy** — `libqtile.lazy.lazy` wikkelt commando's zodat ze pas worden
uitgevoerd op het moment dat je de toets indrukt. Dat is nodig omdat de
configuratie al wordt geladen voordat qtile volledig draait. Zonder `lazy` zou
een commando meteen bij het laden worden uitgevoerd.

**spawn** — start een extern programma, bijvoorbeeld `lazy.spawn("kitty")`.
Qtile start het programma en wacht niet tot het klaar is.

**spawncmd / Prompt** — `lazy.spawncmd()` opent de `widget.Prompt` in de balk.
Daar typ je een shellcommando dat je met Enter uitvoert. Dit is geen rofi.

**Group / werkplek** — een virtueel bureaublad. Elke group heeft een naam, een
optioneel label (hier een icoon), eventueel `matches` en een `spawn`-opdracht.
`persist=True` houdt de group in leven ook zonder vensters. Deze config heeft
negen groups.

**togroup** — `lazy.window.togroup("3", switch_group=True)` verplaatst het
actieve venster naar group 3 en schakelt mee. Zonder `switch_group` blijf je op
de huidige groep.

**Match / wm_class** — `Match(wm_class="kitty")` koppelt een venster aan een
group op basis van de X11-vensterklasse. Die klasse vraag je op met `xprop`.
Chrome, kitty en Spotify hebben hier een vaste group.

**Screen / Output** — een scherm of monitor. `screens` bevat de
scherminstellingen; deze opzet gaat uit van één monitor met een bovenbalk.
`Output` is de nieuwere qtile-abstractie voor een fysieke uitgang.
`fake_screens` en `generate_screens` zijn alternatieven voor bijzondere
multi-monitoropstellingen; die staan hier op `None`.

### Indeling en layouts

**Layout** — het algoritme dat vensters rangschikt. Deze configuratie gebruikt
`TreeTab`, `Bsp`, `Columns` en `Max`. Met
<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> wissel je. Een group kan
eigen layouts krijgen via `Group(layouts=...)`, maar dat is hier niet gebruikt.

**Bsp** — de standaardlayout: bspwm-achtige indeling waarbij elk nieuw venster
de beschikbare ruimte in tweeën splitst, afwisselend horizontaal en verticaal.
Shuffle, grow, normalize en split werken op deze structuur.

**TreeTab** — een boomstructuur in een zijpaneel, waarbij alleen het actieve
venster de rest van het scherm vult. `J`/`K` gaan door de lijst, `H`/`L`
klappen een vertakking in of uit en
<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd>
herschikt vensters binnen de boom.

**Columns** — kolommen naast elkaar, met in elke kolom een stapel vensters.
`H`/`L` gaan tussen kolommen, `J`/`K` binnen een kolom. Shuffle, grow en
normalize werken op deze structuur.

**Max** — elke tegel vult het volledige scherm; je ziet alleen het actieve
venster. Handig voor video, presentaties of gefocust browsen.

**Focus** — het venster dat toetsaanslagen ontvangt. De focusrand gebruikt de
pywal-accentkleur (`color2`), niet-actieve randen zijn `muted` (`color8`).
`follow_mouse_focus` laat de focus de muis volgen.

**Stack / stapel** — de vensters binnen één kolom in Columns. In unsplit-modus
zie je alleen het actieve venster van de stapel; in split-modus zie je ze allemaal.

**split / unsplit** — <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Return</kbd>
wisselt in Bsp de splitrichting van het actieve venster en schakelt in Columns
tussen alle vensters van een stapel tonen (split) en alleen het actieve venster
tonen (unsplit). Dit splitst dus geen nieuwe kolom; het toont of verbergt de
inhoud van de stapel.

**shuffle** — verplaatst het actieve venster binnen de layout: naar een andere
kolom of een andere positie in de stapel. Buiten het bereik maakt qtile een
nieuwe kolom.

**grow** — vergroot of verkleint het actieve venster of de kolom in een
richting. Tegen de schermrand kan dit het venster juist kleiner maken.

**normalize** — zet alle kolommen en stapels terug naar gelijke afmetingen.

**Floating layout** — de aparte layout `layout.Floating` voor zwevende
vensters. Qtile gebruikt die automatisch voor vensters die aan een float-regel
voldoen. `floats_kept_above = True` houdt ze boven de getegelde vensters.

**Fullscreen** — het venster vult het hele scherm, ook over de balk.
`auto_fullscreen = True` laat applicaties zelf fullscreen aanvragen.

### Balk en widgets

**Bar** — de bovenbalk van 44 pixels die qtile tekent. De balk gebruikt
pywal-kleuren en de wallpaper als achtergrond.

**Widget** — een bouwsteen van de balk. Voorbeelden in deze config:
`CurrentLayout`, `GroupBox`, `Prompt`, `WindowName`, `GenPollCommand`,
`Battery`, `PulseVolume`, `Systray`, `Clock` en `TextBox`. Widgets kunnen
muiskliks afhandelen via `mouse_callbacks`.

**GroupBox** — de widget met de negen werkplekken als icoon. Actief is licht,
inactief grijs; klikken schakelt van group. `disable_drag=True` voorkomt dat je
vensters op de balk sleept.

**Systray** — het systeemvak voor achtergrondapps zoals blueman en Vibe Typer.
Deze widget is X11-only; de Wayland-variant heet `StatusNotifier`.

**GenPollCommand** — een widget die met vaste tussenpozen een shellcommando
uitvoert en de uitvoer toont. De weerwidget gebruikt dit met `wttr.in` en
ververst elke 15 minuten.

**PulseVolume** — de volumewidget. Toont een luidspreker-icoon, opent
`pavucontrol` bij een linksklik, dempt bij een rechtsklik en past het volume aan
bij scrollen.

### Configuratie en autostart

**Hook** — een qtile-event dat code uitvoert. `@hook.subscribe.startup_once`
draait één keer bij het starten; zo worden picom, dunst, blueman, het
Bluetooth-script, Vibe Typer, xscreensaver en `set-wallpaper.sh` gestart.

**Autostart** — de programma's die via de `startup_once`-hook beginnen.
`_spawn_if_available()` slaat optionele programma's over als ze niet bestaan,
zodat een ontbrekende app de rest niet blokkeert.

**reload_config** — leest `config.py` opnieuw en past de instellingen toe zonder
de sessie te beëindigen. Sneltoets: <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>R</kbd>.

**shutdown** — stopt qtile en daarmee de X-sessie. Sneltoets:
<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Q</kbd>. Via de CLI:
`qtile cmd-obj -o cmd -f shutdown`.

**VT** — virtual terminal, een tekstconsole op <kbd>Ctrl</kbd> + <kbd>Alt</kbd>
+ <kbd>F1</kbd> … <kbd>F7</kbd>. De qtile-binding werkt alleen onder Wayland; op
X11 regelt Xorg dit. Niet verwarren met kitty: dat is een terminalemulator in
een venster.

**X11 / Wayland** — de twee displayservers die qtile ondersteunt. Deze opzet
draait op X11 (picom, Systray). De `wl_*`-opties en de Wayland-check bij de
VT-binding zijn voorbereidingen op Wayland.

**wmname = "LG3D"** — een werkaround voor Java-apps die denken dat ze onder een
niet-reparenting window manager draaien. Qtile liegt hier bewust; het is geen
echte window manager met die naam.

### Theming en desktopcomponenten

**pywal / pywal16** — haalt een kleurenpalet uit een wallpaper en schrijft dat
naar `~/.cache/wal/`. De qtile-config leest `colors.json` en gebruikt
`special.background` en `special.foreground` voor de basis, `color1` als alert,
`color2` als accent, `color4` als accent2 en `color8` als gedempte tekst.

**wal -n** — de optie `-n` zorgt dat pywal de wallpaper niet zelf zet. Qtile
tekent de achtergrond namelijk via `Screen(wallpaper=...)`.

**QT_QPA_PLATFORMTHEME** — omgevingsvariabele die in `config.py` op `kde` wordt
gezet. Daardoor lezen Qt/KDE-apps zoals Dolphin en Kate het KDE-kleurenschema
dat `apply-kde-theme.sh` met de pywal-kleuren vult, in plaats van een eigen
licht thema.

**set-wallpaper.sh** — het script achter de wallpaperkiezer. Het roept `wal`
aan, werkt het KDE/GTK/dunst/OpenCode-thema bij en herlaadt qtile.

**wallpaper-rotate.timer** — een systemd-user-timer die elke 10 minuten een
andere wallpaper kiest en het kleurenschema bijwerkt.

**picom** — de compositor voor schaduwen, transparantie, afgeronde hoeken en
blur. Zonder picom blijven de vensters vlak.

**rofi** — launcher en menu voor applicaties, vensters, wallpapers en het
power-menu. De kleuren komen uit pywal.

**dunst** — de notificatiedaemon. Toont meldingen en volgt het pywal-thema.

**xscreensaver** — schermbeveiliging en vergrendeling. De daemon start via de
autostart; `lock.sh` vergrendelt de sessie met `xscreensaver-command -lock`.

**kitty** — de terminalemulator en de standaardterminal in deze configuratie.

**rice** — de hobbyterm voor een sterk aangepaste desktop waarbij wallpaper,
kleuren, balk, fonts en widgets één samenhangende stijl vormen.

## Overige instellingen in config.py

| Instelling | Waarde | Wat het doet |
|---|---|---|
| `follow_mouse_focus` | `True` | Focus volgt de muis |
| `bring_front_click` | `False` | Een klik brengt een venster niet automatisch naar voren |
| `floats_kept_above` | `True` | Zwevende vensters blijven boven getegelde vensters |
| `cursor_warp` | `False` | De cursor springt niet naar het gefocuste venster |
| `auto_fullscreen` | `True` | Applicaties mogen zelf fullscreen aanvragen |
| `focus_on_window_activation` | `"smart"` | Een app krijgt alleen focus als dat gepast is |
| `auto_minimize` | `True` | qtile respecteert minimaliseerverzoeken van apps |
| `reconfigure_screens` | `True` | Schermen worden bijgewerkt bij hotplug of resolutiewijziging |
| `screen_change_debounce_timeout` | `1` | Wacht 1 seconde om schermwijzigingen te bundelen |
| `wmname` | `"LG3D"` | Java-workaround voor niet-reparenting window managers |

## Handige commando's

| Commando | Doel |
|---|---|
| `qtile check` | De configuratie op fouten controleren |
| `qtile cmd-obj -o cmd -f reload_config` | De configuratie herladen |
| `qtile cmd-obj -o cmd -f shutdown` | qtile afsluiten |
| `qtile shell` | Interactieve shell voor de qtile-commandinterface |
| `qtile --version` | De geïnstalleerde versie tonen |

## Bronnen

- [Qtile-documentatie](https://docs.qtile.org/)
- [Keybindings en lazy commands](https://docs.qtile.org/en/latest/manual/config/lazy.html)
- [Layouts](https://docs.qtile.org/en/latest/manual/layouts.html)
- [Deze configuratie op GitHub](https://github.com/simondewaal1980/qtile-rice)

---

*Bijgewerkt op 20 oktober 2026 voor qtile 0.34 (X11).*

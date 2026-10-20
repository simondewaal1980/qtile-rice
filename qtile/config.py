import json
import os
import shutil
import subprocess
from collections.abc import Callable

import libqtile.resources
from libqtile import bar, hook, layout, qtile, widget
from libqtile.config import Click, Drag, DropDown, Group, Key, Match, ScratchPad, Screen

try:  # qtile >= 0.35 exporteert Output; Ubuntu 26.04 (qtile 0.34) nog niet.
    from libqtile.config import Output
except ImportError:  # type: ignore[assignment,misc]
    Output = object
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

mod = "mod4"
# Kubuntu: expliciet kitty als standaardterminal (i.p.v. guess_terminal()).
terminal = "kitty"

# Qt/KDE-apps (Dolphin, Kate, Gwenview, ...) gebruiken buiten Plasma standaard
# een eigen licht palet. Met de KDE-platformthema-plugin lezen ze kdeglobals,
# dat apply-kde-theme.sh met het pywal-kleurenschema vult. Zo volgen ze
# dezelfde donkere kleuren als de rest van de desktop.
os.environ.setdefault("QT_QPA_PLATFORMTHEME", "kde")

# KDE's kbuildsycoca6 zoekt zonder XDG_MENU_PREFIX naar applications.menu,
# dat op dit systeem niet bestaat (wel plasma-applications.menu). Dan blijft
# de KDE-dienstdatabase onvolledig en werken bestandskoppelingen in Dolphin
# niet. De prefix zorgt dat de database met het juiste menu wordt opgebouwd.
os.environ.setdefault("XDG_MENU_PREFIX", "plasma-")


def _script(name: str) -> str:
    """Volledig pad naar een script in ~/.config/qtile/scripts."""
    return os.path.expanduser(f"~/.config/qtile/scripts/{name}")


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key(
        [mod],
        "h",
        lazy.layout.left().when(layout=["bsp", "columns"]),
        lazy.layout.collapse_branch().when(layout="treetab"),
        desc="Focus left / collapse tree branch",
    ),
    Key(
        [mod],
        "l",
        lazy.layout.right().when(layout=["bsp", "columns"]),
        lazy.layout.expand_branch().when(layout="treetab"),
        desc="Focus right / expand tree branch",
    ),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch rofi application launcher"),
    Key([mod], "Tab", lazy.spawn("rofi -show window"), desc="Switch window with rofi"),
    # Schermafdrukken: Print opent Spectacle, waarin je gebied, venster of
    # volledig scherm kiest en de opname kunt opslaan of kopiëren.
    Key([], "Print", lazy.spawn("spectacle"), desc="Schermafdruk maken met Spectacle"),
    # Mediatoetsen: play/pause en volgende/vorige track via MPRIS.
    Key(
        [],
        "XF86AudioPlay",
        lazy.spawn(f"{_script('media-control.sh')} play-pause"),
        desc="Afspelen/pauzeren",
    ),
    Key(
        [],
        "XF86AudioNext",
        lazy.spawn(f"{_script('media-control.sh')} next"),
        desc="Volgende track",
    ),
    Key(
        [],
        "XF86AudioPrev",
        lazy.spawn(f"{_script('media-control.sh')} previous"),
        desc="Vorige track",
    ),
    # Volume van de standaardsink (pactl; werkt met PulseAudio en PipeWire).
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn(f"{_script('volume.sh')} up"),
        desc="Volume omhoog",
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn(f"{_script('volume.sh')} down"),
        desc="Volume omlaag",
    ),
    Key(
        [],
        "XF86AudioMute",
        lazy.spawn(f"{_script('volume.sh')} mute"),
        desc="Volume dempen",
    ),
    Key(
        [],
        "XF86AudioMicMute",
        lazy.spawn(f"{_script('volume.sh')} mic-mute"),
        desc="Microfoon dempen",
    ),
    # Helderheid van het paneel (systemd-logind; terugval op xrandr).
    Key(
        [],
        "XF86MonBrightnessUp",
        lazy.spawn(f"{_script('brightness.sh')} up"),
        desc="Helderheid omhoog",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        lazy.spawn(f"{_script('brightness.sh')} down"),
        desc="Helderheid omlaag",
    ),
    # Scherm vergrendelen: XF86ScreenSaver op sommige laptops, Super+Escape
    # werkt altijd.
    Key(
        [],
        "XF86ScreenSaver",
        lazy.spawn(_script("lock.sh")),
        desc="Scherm vergrendelen",
    ),
    Key(
        [mod],
        "Escape",
        lazy.spawn(_script("lock.sh")),
        desc="Scherm vergrendelen",
    ),
    Key(
        [mod],
        "o",
        lazy.layout.next().when(layout=["bsp", "columns"]),
        desc="Move window focus to other window",
    ),
    # Move windows. In Bsp/Columns: shuffle within the tiling. In TreeTab:
    # move the window within the tree (up/down) or out of its branch (left).
    Key(
        [mod, "shift"],
        "h",
        lazy.layout.shuffle_left().when(layout=["bsp", "columns"]),
        lazy.layout.move_left().when(layout="treetab"),
        desc="Move window left / out of tree branch",
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right().when(layout=["bsp", "columns"]),
        lazy.layout.move_right().when(layout="treetab"),
        desc="Move window right / into previous tree branch",
    ),
    Key(
        [mod, "shift"],
        "j",
        lazy.layout.shuffle_down().when(layout=["bsp", "columns"]),
        lazy.layout.move_down().when(layout="treetab"),
        desc="Move window down",
    ),
    Key(
        [mod, "shift"],
        "k",
        lazy.layout.shuffle_up().when(layout=["bsp", "columns"]),
        lazy.layout.move_up().when(layout="treetab"),
        desc="Move window up",
    ),
    # Grow windows in Bsp/Columns. In TreeTab these keys resize the panel.
    Key(
        [mod, "control"],
        "h",
        lazy.layout.grow_left().when(layout=["bsp", "columns"]),
        lazy.layout.decrease_ratio().when(layout="treetab"),
        desc="Grow window left / shrink tree panel",
    ),
    Key(
        [mod, "control"],
        "l",
        lazy.layout.grow_right().when(layout=["bsp", "columns"]),
        lazy.layout.increase_ratio().when(layout="treetab"),
        desc="Grow window right / widen tree panel",
    ),
    Key(
        [mod, "control"],
        "j",
        lazy.layout.grow_down().when(layout=["bsp", "columns"]),
        desc="Grow window down",
    ),
    Key(
        [mod, "control"],
        "k",
        lazy.layout.grow_up().when(layout=["bsp", "columns"]),
        desc="Grow window up",
    ),
    Key(
        [mod],
        "n",
        lazy.layout.normalize().when(layout=["bsp", "columns"]),
        desc="Reset all window sizes",
    ),
    # Bsp: wissel de splitrichting van het huidige venster (horizontaal/
    # verticaal). Columns: toon alle stapels of juist één venster per stapel.
    # (Super+Shift+Return is gereserveerd voor de scratchpad.)
    Key(
        [mod, "shift"],
        "s",
        lazy.layout.toggle_split().when(layout=["bsp", "columns"]),
        desc="Toggle split direction (Bsp) / split view (Columns)",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod, "shift"], "b", lazy.spawn("google-chrome-stable"), desc="Launch Google Chrome"),
    Key([mod, "shift"], "f", lazy.spawn("dolphin"), desc="Launch Dolphin (bestandsbeheer)"),
    Key(
        [mod, "shift"],
        "m",
        lazy.spawn(["flatpak", "run", "com.spotify.Client"]),
        desc="Launch Spotify",
    ),
    # Dropdown-terminal (Quake-stijl): nogmaals indrukken verbergt hem,
    # focus verliezen doet hetzelfde. De kitty-instance krijgt een eigen
    # WM_CLASS, zodat hij niet door de gewone kitty-regel wordt opgevangen.
    Key(
        [mod, "shift"],
        "Return",
        lazy.group["scratchpad"].dropdown_toggle("kitty"),
        desc="Toon/verberg de kitty-scratchpad",
    ),
    # Toggle between different layouts as defined below
    Key([mod, "shift"], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    # Wallpaper kiezen -> pywal genereert een nieuw kleurenschema.
    Key(
        [mod, "shift"],
        "w",
        lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/wallpaper-pick.sh")),
        desc="Kies wallpaper en pas het kleurenschema aan",
    ),
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


# --- Werkplekken -----------------------------------------------------------
# De naam blijft 1 t/m 9, zodat mod+1 ... mod+9 ongewijzigd werkt. In de balk
# tonen we echter een Font Awesome-icoon in plaats van het cijfer.
# 'matches' zorgt dat een later gestart venster automatisch op de juiste
# werkplek belandt; 'spawn' start de vaste apps bij het inloggen.
# Indeling: 1 browser | 2 terminal | 3 bestanden | 4 code | 5 documenten
#           6 foto's  | 7 video    | 8 games     | 9 Spotify
workspaces = [
    # naam, icoon, vensterregels, programma dat bij het inloggen start
    ("1", "\uf268", [Match(wm_class="google-chrome")], "google-chrome-stable"),
    ("2", "\uf120", [Match(wm_class="kitty")], terminal),
    ("3", "\uf07b", [], None),
    ("4", "\uf121", [], None),
    ("5", "\uf02d", [], None),
    ("6", "\uf03e", [], None),
    ("7", "\uf008", [], None),
    ("8", "\uf11b", [], None),
    ("9", "\uf1bc", [Match(wm_class="spotify")], ["flatpak", "run", "com.spotify.Client"]),
]

groups = [
    Group(name, label=icon, matches=matches, spawn=spawn)
    for name, icon, matches, spawn in workspaces
]

for i in groups:
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod + shift + group number = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

# --- Scratchpad: dropdown-terminal -----------------------------------------
# Een verborgen groep waarin de kitty-dropdown woont. Super+Shift+Enter haalt
# hem van boven het scherm (Quake-stijl) en stopt hem weer weg. De eigen
# WM_CLASS ('scratchpad') voorkomt dat de groep-Match van werkplek 2 hem pakt.
scratchpad = ScratchPad(
    "scratchpad",
    dropdowns=[
        DropDown(
            "kitty",
            f"{terminal} --class=scratchpad",
            match=Match(wm_class="scratchpad"),
            x=0.0,
            y=0.0,
            width=1.0,
            height=0.45,
            # kitty zelf is al transparant (background_opacity 0.75); laat
            # Qtile daar geen tweede transparantielaag bovenop leggen.
            opacity=1.0,
            on_focus_lost_hide=True,
        )
    ],
)
groups.append(scratchpad)

# --- Kleurenschema uit de wallpaper (pywal) --------------------------------
# 'set-wallpaper.sh' schrijft de kleuren naar ~/.cache/wal/colors.json.
# Hieronder lezen we ze in, zodat de balk, widgets en vensterranden
# automatisch meeveranderen met de achtergrond.
_wal_cache = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "wal"
)

try:
    with open(os.path.join(_wal_cache, "colors.json"), encoding="utf-8") as _fh:
        _wal = json.load(_fh)
except (OSError, ValueError):
    _wal = {}

_special = _wal.get("special", {})
_palette = _wal.get("colors", {})

# Terugvalkleuren voor als pywal (nog) geen schema heeft gegenereerd.
background = _special.get("background", "#1d2021")
foreground = _special.get("foreground", "#ebdbb2")
accent = _palette.get("color2", "#458588")
accent2 = _palette.get("color4", "#83a598")
alert = _palette.get("color1", "#cc241d")
muted = _palette.get("color8", "#928374")
surface = _palette.get("color0", "#282828")

layouts = [
    # Bsp is Qtile's bspwm-achtige indeling: elk nieuw venster splitst de
    # beschikbare ruimte in tweeën (afwisselend horizontaal/verticaal).
    # Staat bovenaan, dus standaard actief.
    # Met mod+shift+Tab wissel je naar TreeTab, Columns of Max.
    layout.Bsp(
        border_focus=accent,
        border_normal=muted,
        border_width=4,
        border_on_single=True,
        ratio=1.6,
    ),
    # TreeTab toont de vensters als boom in een zijpaneel; het actieve venster
    # vult de rest van het scherm.
    layout.TreeTab(
        font="Noto Sans",
        fontsize=14,
        section_fontsize=12,
        panel_width=220,
        bg_color=background,
        active_bg=accent,
        active_fg=background,
        inactive_bg=surface,
        inactive_fg=foreground,
        urgent_bg=alert,
        urgent_fg=background,
        section_fg=accent2,
        border_width=2,
        sections=["Vensters"],
    ),
    layout.Columns(
        border_focus=accent,
        border_normal=muted,
        border_focus_stack=[accent, alert],
        border_width=4,
    ),
    layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="Noto Sans",
    fontsize=18,
    padding=6,
    foreground=foreground,
)
extension_defaults = widget_defaults.copy()

logo = os.path.join(os.path.dirname(libqtile.resources.__file__), "logo.png")

# --- Weerwidget ------------------------------------------------------------
# Haalt het actuele weer op voor Eindhoven via wttr.in (geen API-sleutel nodig).
# De widget ververst elke 15 minuten en werkt alleen met een internetverbinding.
weather_command = (
    "curl -s --max-time 10 --get 'https://wttr.in/Eindhoven' "
    "--data-urlencode 'format=Eindhoven: %c %t  %C  wind %w  vocht %h'"
)

# Huidige wallpaper: bij voorkeur de laatste die pywal gebruikte.
# (qtile tekent de achtergrond zelf; pywal wordt met '-n' aangeroepen.)
wallpaper = _wal.get("wallpaper") or os.path.expanduser(
    "~/.local/share/wallpapers/acropolis.jpg"
)
screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(mode="icon", scale=0.7, padding=8),
                widget.GroupBox(
                    font="FontAwesome",
                    fontsize=20,
                    active=foreground,
                    inactive=muted,
                    highlight_method="block",
                    block_highlight_text_color=background,
                    this_current_screen_border=accent,
                    other_current_screen_border=muted,
                    urgent_border=alert,
                    rounded=True,
                    borderwidth=0,
                    padding_x=9,
                    padding_y=3,
                    margin_x=6,
                    margin_y=5,
                    spacing=4,
                    disable_drag=True,
                ),
                widget.Prompt(),
                widget.Sep(linewidth=1, padding=8, foreground=muted),
                widget.WindowName(),
                widget.GenPollCommand(
                    name="weather",
                    cmd=weather_command,
                    shell=True,
                    update_interval=900,
                    foreground=accent2,
                    mouse_callbacks={
                        "Button3": lazy.spawn("xdg-open 'https://wttr.in/Eindhoven'")
                    },
                ),
                # Accu: icoon + percentage. Ververs elke 30 seconden; onder de
                # 15% kleurt het percentage rood (alert). Tijdens het laden
                # staat er een bliksem, anders een accu-icoon.
                widget.Battery(
                    name="battery",
                    format="{char} {percent:2.0%}",
                    charge_char="⚡",
                    discharge_char="🔋",
                    full_char="🔋",
                    empty_char="🪫",
                    not_charging_char="🔌",
                    unknown_char="❓",
                    # Ook bij 100% het icoon + percentage tonen i.p.v. "Full".
                    show_short_text=False,
                    low_percentage=0.15,
                    low_foreground=alert,
                    foreground=accent2,
                    update_interval=30,
                ),
                # Volume-regelaar: toont 🔊 (+ mute-icoon) van de standaardsink.
                # Linksklik opent de geluidsinstellingen (pavucontrol),
                # rechtsklik dempt, scrollen past het volume aan.
                widget.PulseVolume(
                    name="volume",
                    emoji=True,
                    foreground=accent2,
                    mute_foreground=alert,
                    mouse_callbacks={
                        "Button1": lazy.spawn("pavucontrol"),
                        "Button3": lazy.widget["volume"].mute(),
                    },
                ),
                # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
                # widget.StatusNotifier(),
                widget.Systray(),
                widget.TextBox(
                    "\uf017",
                    font="FontAwesome",
                    fontsize=17,
                    foreground=accent2,
                    padding=4,
                ),
                widget.Clock(format="%a %d %b  %H:%M"),
                # Power-knop: klik opent een dropdown (rofi) met uitzetten,
                # opnieuw opstarten en uitloggen.
                widget.TextBox(
                    "\uf011",
                    name="power",
                    font="FontAwesome",
                    fontsize=17,
                    foreground=alert,
                    padding=6,
                    mouse_callbacks={
                        "Button1": lazy.spawn(
                            os.path.expanduser("~/.config/qtile/scripts/power-menu.sh")
                        )
                    },
                ),
            ],
            44,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
        background=background,
        wallpaper=wallpaper,
        wallpaper_mode="fill",
        # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
        # By default we handle these events delayed to already improve performance, however your system might still be struggling
        # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
        # x11_drag_polling_rate = 60,
    ),
]

# --- Balk verbergen bij fullscreen -----------------------------------------
# Op X11 houdt Qtile de balk niet automatisch onder een fullscreen-venster.
# Daardoor kan de balk boven een video op volledig scherm (bijv. YouTube)
# komen te staan. Verberg de balk zolang er op dat scherm een venster op
# volledig scherm staat en toon hem weer als dat venster sluit of verkleint.

@hook.subscribe.float_change
@hook.subscribe.changegroup
@hook.subscribe.client_managed
@hook.subscribe.startup
@hook.subscribe.screens_reconfigured
def _update_bar_visibility(*_args: object) -> None:
    for screen in qtile.screens:
        top = screen.top
        if screen.group is None or not isinstance(top, bar.Bar):
            continue

        fullscreen = any(window.fullscreen for window in screen.group.windows)
        # Onthoud of wij de balk hebben verborgen; een balk die de gebruiker
        # zelf heeft verborgen moet niet ineens terugkomen.
        hidden = getattr(top, "_hidden_for_fullscreen", False)

        if fullscreen and top.is_show():
            top.show(False)
            top._hidden_for_fullscreen = True
        elif not fullscreen and hidden:
            top.show(True)
            top._hidden_for_fullscreen = False


@hook.subscribe.client_killed
def _show_bar_after_client_close(_window: object) -> None:
    # 'client_killed' komt binnen voordat het venster uit de groep verdwenen
    # is. Wacht daarom kort, zodat een nog aanwezig fullscreen-venster de
    # balk niet meteen weer laat verschijnen.
    qtile.call_later(0.1, _update_bar_visibility)


# Instead of screens, you can define a function here to specify which Screen
# should correspond to which Output.
fake_screens: list[Screen] | None = None

# Instead of screens or fake screens, you can define a function here that
# returns a list of Screen objects based on the list of Outputs; that way you
# can decide based on e.g. the number of screens, or which ports are plugged
# in exactly what do render in each bar for each screen.
generate_screens: Callable[[list[Output]], list[Screen]] | None = None

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True

# How long (in seconds) to wait after a screen change event before firing the
# screen_change hook, coalescing bursts of events into a single one.
screen_change_debounce_timeout = 1

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

idle_timers = []  # type: list
idle_inhibitors = []  # type: list

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"


# --- Autostart -------------------------------------------------------------
# Draait één keer bij het starten van de sessie:
#   1. de compositor picom (schaduwen, transparantie, afgeronde hoeken);
#   2. de notificatiedaemon dunst (thema volgt pywal);
#   3. het Bluetooth-tray-icoon (blueman-applet) voor de Systray-widget in de
#      bar; klik erop voor het menu, dubbelklik opent blueman-manager;
#   4. het script dat de soundcore Space One Pro automatisch verbindt en het
#      geluid naar de koptelefoon routeert;
#   5. Vibe Typer (AppImage) met --autostart: start verborgen in het systeemvak;
#   6. xscreensaver, voor schermvergrendeling en schermbeveiliging;
#   7. het wallpaperscript, dat een kleurenschema genereert en qtile herlaadt;
#   8. de Qt/KDE-omgevingsvariabele voor de systemd-user-manager, zodat ook
#      via D-Bus gestarte Qt-apps het Breeze/pywal-thema gebruiken.

def _spawn_if_available(*cmd: str) -> None:
    """Start alleen programma's die daadwerkelijk bestaan.

    Optionele autostart-items (blueman, een AppImage, ...) mogen op een andere
    machine dan deze de rest van de autostart niet blokkeren.
    """
    executable = cmd[0]
    if os.path.isabs(executable):
        if not os.path.exists(executable):
            return
    elif shutil.which(executable) is None:
        return
    try:
        subprocess.Popen(list(cmd))
    except OSError:
        pass


@hook.subscribe.startup_once
def autostart() -> None:
    # Kubuntu: geef DISPLAY/XAUTHORITY door aan de systemd-user-manager, zodat
    # de wallpaper-rotate.timer (systemd) een werkende X-verbinding heeft.
    _spawn_if_available(
        "systemctl", "--user", "import-environment", "DISPLAY", "XAUTHORITY"
    )
    # Qt-apps die via D-Bus/systemd gestart worden, moeten dezelfde KDE-
    # platformthema-plugin gebruiken als de apps die qtile direct start.
    _spawn_if_available(
        "systemctl",
        "--user",
        "set-environment",
        f"QT_QPA_PLATFORMTHEME={os.environ.get('QT_QPA_PLATFORMTHEME', 'kde')}",
    )
    _spawn_if_available(
        "picom", "--config", os.path.expanduser("~/.config/picom/picom.conf")
    )
    _spawn_if_available("dunst")
    _spawn_if_available("blueman-applet")
    _spawn_if_available(
        os.path.expanduser("~/.config/qtile/scripts/bluetooth-soundcore.sh")
    )
    _spawn_if_available(
        os.path.expanduser("~/AppImages/VibeTyper.AppImage"), "--autostart"
    )
    _spawn_if_available("xscreensaver", "-no-splash")
    _spawn_if_available(
        os.path.expanduser("~/.config/qtile/scripts/set-wallpaper.sh")
    )

import json
import os
import subprocess
from collections.abc import Callable

import libqtile.resources
from libqtile import bar, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Output, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

mod = "mod4"
terminal = guess_terminal()

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch rofi application launcher"),
    Key([mod], "Tab", lazy.spawn("rofi -show window"), desc="Switch window with rofi"),
    Key([mod], "o", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
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


groups = [Group(i) for i in "123456789"]

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

layouts = [
    layout.Columns(
        border_focus=accent,
        border_normal=muted,
        border_focus_stack=[accent, alert],
        border_width=4,
    ),
    layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
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
                widget.CurrentLayout(),
                widget.GroupBox(
                    active=accent,
                    inactive=foreground,
                    highlight_method="text",
                    this_current_screen_border=accent,
                    other_current_screen_border=muted,
                    urgent_border=alert,
                ),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": (alert, foreground),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.TextBox("default config", name="default"),
                widget.TextBox("Press &lt;M-r&gt; to spawn", foreground=accent2),
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
                # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
                # widget.StatusNotifier(),
                widget.Systray(),
                widget.Clock(format="%Y-%m-%d %a %I:%M %p"),
                widget.QuickExit(),
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
#   2. het wallpaperscript, dat een kleurenschema genereert en qtile herlaadt.
@hook.subscribe.startup_once
def autostart() -> None:
    subprocess.Popen(
        ["picom", "--config", os.path.expanduser("~/.config/picom/picom.conf")]
    )
    subprocess.Popen(
        [os.path.expanduser("~/.config/qtile/scripts/set-wallpaper.sh")]
    )

#!/usr/bin/env python3
"""
Apple Liquid Glass Powermenu for Hyprland
- Native Wayland Layer Shell (namespace: logout_dialog)
- Single row of 6 circular Liquid Glass action buttons
- Modern vector icons inside circles
- Labels and keybind hints placed underneath each button
- Dynamic header: "What do you want the [hostname] to do?"
"""

import sys, os, socket, subprocess, json
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

hostname = socket.gethostname()

win = Gtk.Window()
GtkLayerShell.init_for_window(win)
GtkLayerShell.set_namespace(win, 'logout_dialog')
GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.EXCLUSIVE)
GtkLayerShell.set_exclusive_zone(win, -1)

for edge in [GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM, GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT]:
    GtkLayerShell.set_margin(win, edge, 0)
    GtkLayerShell.set_anchor(win, edge, True)

# Set monitor: check cli argument, cursor position, or focused monitor
target_monitor = None
try:
    display = Gdk.Display.get_default()
    if display:
        target_name = None
        if len(sys.argv) > 1 and sys.argv[1].startswith("--monitor"):
            if "=" in sys.argv[1]:
                target_name = sys.argv[1].split("=")[1]
            elif len(sys.argv) > 2:
                target_name = sys.argv[2]

        mons_json = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j'], timeout=0.5).decode())

        if target_name:
            # Match by name
            for m in mons_json:
                if m.get('name') == target_name:
                    mx, my = m['x'], m['y']
                    for i in range(display.get_n_monitors()):
                        gm = display.get_monitor(i)
                        g = gm.get_geometry()
                        if g.x == mx and g.y == my:
                            target_monitor = gm
                            break
                    break

        if not target_monitor:
            # Match by cursor position
            cursor = subprocess.check_output(['hyprctl', 'cursorpos'], timeout=0.5).decode().strip()
            cx, cy = [int(v.strip()) for v in cursor.split(',')]
            for i in range(display.get_n_monitors()):
                gm = display.get_monitor(i)
                g = gm.get_geometry()
                if g.x <= cx < g.x + g.width and g.y <= cy < g.y + g.height:
                    target_monitor = gm
                    break

        if not target_monitor:
            # Fallback to focused monitor in hyprland
            f = next((m for m in mons_json if m.get('focused')), mons_json[0])
            fx, fy = f['x'], f['y']
            for i in range(display.get_n_monitors()):
                gm = display.get_monitor(i)
                g = gm.get_geometry()
                if g.x == fx and g.y == fy:
                    target_monitor = gm
                    break

        if target_monitor:
            GtkLayerShell.set_monitor(win, target_monitor)
except Exception:
    pass

css = b'''
* {
    background-image: none;
    box-shadow: none;
}

window {
    background-color: rgba(10, 15, 26, 0.40);
}

.title-label {
    font-family: "Outfit", "Inter", -apple-system, sans-serif;
    font-size: 26px;
    font-weight: 600;
    color: #ffffff;
    text-shadow: 0 2px 12px rgba(0, 0, 0, 0.70);
}

.subtitle-label {
    font-family: "Outfit", "Inter", -apple-system, sans-serif;
    font-size: 13.5px;
    font-weight: 500;
    color: rgba(240, 246, 252, 0.65);
    text-shadow: 0 1px 4px rgba(0, 0, 0, 0.5);
}

.glass-btn {
    min-width: 100px;
    min-height: 100px;
    border-radius: 50px;
    border: 1.5px solid rgba(255, 255, 255, 0.22);
    background-color: rgba(26, 36, 58, 0.52);
    box-shadow: inset 0 1px 1px 0 rgba(255, 255, 255, 0.42),
                inset 0 0 16px 0 rgba(255, 255, 255, 0.05),
                0 16px 36px 0 rgba(0, 0, 0, 0.45);
    transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
    outline-style: none;
    margin: 0px;
    padding: 0px;
}

.glass-btn:hover {
    background-color: rgba(38, 52, 82, 0.72);
    border-color: rgba(255, 255, 255, 0.60);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                inset 0 0 20px 0 rgba(255, 255, 255, 0.12),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-lock:hover {
    border-color: rgba(203, 166, 247, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(203, 166, 247, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-suspend:hover {
    border-color: rgba(137, 220, 235, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(137, 220, 235, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-logout:hover {
    border-color: rgba(250, 179, 135, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(250, 179, 135, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-hibernate:hover {
    border-color: rgba(116, 199, 236, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(116, 199, 236, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-reboot:hover {
    border-color: rgba(166, 227, 161, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(166, 227, 161, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.btn-shutdown:hover {
    border-color: rgba(243, 139, 168, 0.85);
    box-shadow: inset 0 1px 2px 0 rgba(255, 255, 255, 0.70),
                0 0 28px 0 rgba(243, 139, 168, 0.40),
                0 20px 42px 0 rgba(0, 0, 0, 0.55);
}

.action-label {
    font-family: "Outfit", "Inter", -apple-system, sans-serif;
    font-size: 14px;
    font-weight: 600;
    color: #f0f6fc;
    text-shadow: 0 1px 4px rgba(0, 0, 0, 0.6);
}

.keybind-pill {
    font-family: "JetBrainsMono Nerd Font Propo", monospace;
    font-size: 11px;
    font-weight: 600;
    color: rgba(240, 246, 252, 0.75);
    background-color: rgba(255, 255, 255, 0.10);
    border: 1px solid rgba(255, 255, 255, 0.16);
    border-radius: 6px;
    padding: 1px 6px;
}
'''

provider = Gtk.CssProvider()
provider.load_from_data(css)
Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

# Outer EventBox catching outside clicks to dismiss
outer_box = Gtk.EventBox()
outer_box.connect('button-press-event', lambda w, e: Gtk.main_quit())

center_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=42)
center_box.set_halign(Gtk.Align.CENTER)
center_box.set_valign(Gtk.Align.CENTER)
outer_box.add(center_box)
win.add(outer_box)

# 1. Header Section: "What do you want the [hostname] to do?"
header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
header_box.set_halign(Gtk.Align.CENTER)

title = Gtk.Label()
title.set_markup(f'What do you want the <span foreground="#cba6f7"><b>{hostname}</b></span> to do?')
title.get_style_context().add_class('title-label')
header_box.pack_start(title, False, False, 0)

subtitle = Gtk.Label(label="Select an option below or press Escape to cancel")
subtitle.get_style_context().add_class('subtitle-label')
header_box.pack_start(subtitle, False, False, 0)

center_box.pack_start(header_box, False, False, 0)

# 2. Single Row of 6 Actions
row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=30)
row_box.set_halign(Gtk.Align.CENTER)
center_box.pack_start(row_box, False, False, 0)

actions = [
    ("Lock", "l", "btn-lock", "/home/xoviax/.config/wlogout/icons/lock.svg", "/home/xoviax/.config/hypr/scripts/lock.sh"),
    ("Suspend", "u", "btn-suspend", "/home/xoviax/.config/wlogout/icons/suspend.svg", "systemctl suspend"),
    ("Logout", "e", "btn-logout", "/home/xoviax/.config/wlogout/icons/logout.svg", "/home/xoviax/.config/hypr/scripts/logout.sh"),
    ("Hibernate", "h", "btn-hibernate", "/home/xoviax/.config/wlogout/icons/hibernate.svg", "systemctl hibernate"),
    ("Reboot", "r", "btn-reboot", "/home/xoviax/.config/wlogout/icons/reboot.svg", "systemctl reboot"),
    ("Shutdown", "s", "btn-shutdown", "/home/xoviax/.config/wlogout/icons/shutdown.svg", "systemctl poweroff"),
]

def run_cmd(cmd):
    Gtk.main_quit()
    if cmd:
        subprocess.Popen(cmd, shell=True)

for name, key, css_cls, icon_path, cmd in actions:
    col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
    col.set_halign(Gtk.Align.CENTER)

    # Circular Button with Icon
    btn = Gtk.Button()
    btn.set_can_focus(False)
    btn.get_style_context().add_class('glass-btn')
    btn.get_style_context().add_class(css_cls)

    if os.path.exists(icon_path):
        img = Gtk.Image.new_from_file(icon_path)
        img.set_pixel_size(42)
        btn.set_image(img)
        btn.set_always_show_image(True)

    btn.connect('clicked', lambda b, c=cmd: run_cmd(c))
    col.pack_start(btn, False, False, 0)

    # Label Box Underneath
    label_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    label_box.set_halign(Gtk.Align.CENTER)

    lbl = Gtk.Label(label=name)
    lbl.get_style_context().add_class('action-label')
    label_box.pack_start(lbl, False, False, 0)

    key_lbl = Gtk.Label(label=key.upper())
    key_lbl.get_style_context().add_class('keybind-pill')
    label_box.pack_start(key_lbl, False, False, 0)

    col.pack_start(label_box, False, False, 0)
    row_box.pack_start(col, False, False, 0)

def on_key_press(w, event):
    key = Gdk.keyval_name(event.keyval)
    if key in ['Escape', 'q', 'Q']:
        Gtk.main_quit()
        return True
    key_map = {
        'l': actions[0][4], 'L': actions[0][4],
        'u': actions[1][4], 'U': actions[1][4],
        'e': actions[2][4], 'E': actions[2][4],
        'h': actions[3][4], 'H': actions[3][4],
        'r': actions[4][4], 'R': actions[4][4],
        's': actions[5][4], 'S': actions[5][4],
    }
    if key in key_map:
        run_cmd(key_map[key])
        return True
    return False

win.connect('key-press-event', on_key_press)
win.show_all()
Gtk.main()

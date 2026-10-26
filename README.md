<div align="center">

# ❄️ Xoviax's Dotfiles

*A modern, performance-oriented **Hyprland** desktop setup running on **CachyOS**, configured with **native Lua** and styled in **Catppuccin Mocha**.*

[![OS](https://img.shields.io/badge/OS-CachyOS%20%2F%20Arch%20Linux-blue?style=for-the-badge&logo=arch-linux)](https://cachyos.org)
[![WM](https://img.shields.io/badge/WM-Hyprland%20v0.56+-00b4d8?style=for-the-badge&logo=wayland)](https://hyprland.org)
[![Config](https://img.shields.io/badge/Config-Native%20Lua%205.5-000080?style=for-the-badge&logo=lua)](https://wiki.hypr.land)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?style=for-the-badge&logo=catppuccin)](https://github.com/catppuccin/catppuccin)
[![Manager](https://img.shields.io/badge/Managed%20with-chezmoi-brightgreen?style=for-the-badge&logo=homebrew)](https://www.chezmoi.io)

</div>

---

## 🖥️ System Overview

| Component | Software / Details |
| :--- | :--- |
| **Operating System** | [CachyOS](https://cachyos.org) (Arch Linux optimized kernel) |
| **Compositor** | [Hyprland](https://hyprland.org) configured natively in **Lua** |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) with Catppuccin pill styling & interactive widgets |
| **Session / Power Menu** | [wlogout](https://github.com/ArtsyMacaw/wlogout) (dynamic per-monitor centering) + [Rofi](https://github.com/davatorium/rofi) |
| **Screen Locker** | [hyprlock](https://github.com/hyprwm/hyprlock) (Catppuccin Mocha clock & login) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Shell** | Zsh + Powerlevel10k |
| **Application Launcher** | Rofi (Type-2 Catppuccin theme) |
| **Notification Center** | [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) |
| **File Manager** | Nautilus |
| **Hardware Display** | HYTE Y70 Touch Screen system monitor automation (`tclock` + `btop`) |

---

## ✨ Features

- **🚀 Native Lua Configuration**: Fully ported to Hyprland's `hl.*` Lua 5.5 configuration engine (`hyprland.lua`), featuring clean modular `require()` imports, programmatic loops for workspace bindings, and event hooks.
- **🎨 Catppuccin Mocha Everywhere**: Cohesive color palette applied across Hyprland window borders, Waybar pills, Wlogout buttons, Rofi launcher, Kitty, and Hyprlock.
- **🖥️ Smart Multi-Monitor Setup**:
  - **DP-3** (2560×1440 @ 165Hz) — Primary gaming display (Workspaces 1–5)
  - **DP-2** (1920×1080 @ 144Hz) — Secondary landscape display (Workspaces 6–7)
  - **HDMI-A-1** (1920×1080 vertical, 90° rotation) — Document & coding monitor (Workspaces 8–9)
  - **DP-1** (HYTE Y70 Touch, 270° rotation) — Dedicated chassis display (Workspace 10)
- **📐 Fixed-Size Power Menu**: Custom monitor-aware launcher calculates exact pixel margins on the fly so buttons remain consistent (130px × 130px) whether summoned on landscape, portrait, or ultrawide screens.
- **🤖 HYTE Y70 Automation**: Startup script (`hyte_y70_display.sh`) automatically tiles `tclock` and `btop` with a `-0.69` split ratio on Workspace 10 with dual-engine (Lua + Hyprlang) IPC compatibility.
- **🔒 Secure Screen Locking**: Hyprlock styled with blurred backgrounds, date/time typography, and unified lock script fallback (`lock.sh`).

---

## ⌨️ Keybindings Reference

### Window & Session Management

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Launch Terminal (`kitty`) |
| <kbd>Super</kbd> + <kbd>W</kbd> | Close Active Window |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Open File Manager (`nautilus`) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Open Application Launcher (`rofi`) |
| <kbd>Super</kbd> + <kbd>V</kbd> | Toggle Floating Mode |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>Super</kbd> + <kbd>P</kbd> | Toggle Pseudo-tiling |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>J</kbd> | Toggle Dwindle Split Direction |
| <kbd>Super</kbd> + <kbd>R</kbd> | Reload Waybar (`launch.sh`) |
| <kbd>Super</kbd> + <kbd>N</kbd> | Toggle Notification Center (`swaync`) |

### Power & Session Menu

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Escape</kbd> or <kbd>Backspace</kbd> | Open / Toggle Power Menu (`wlogout`) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Lock Screen immediately (`hyprlock`) |
| <kbd>Power Button</kbd> | Open Power Menu |

*Inside the Power Menu:* <kbd>L</kbd> Lock · <kbd>U</kbd> Suspend · <kbd>E</kbd> Logout · <kbd>H</kbd> Hibernate · <kbd>R</kbd> Reboot · <kbd>S</kbd> Shutdown · <kbd>Esc</kbd> Cancel

### Navigation & Workspaces

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Focus Left / Down / Up / Right (Vim keys) |
| <kbd>Super</kbd> + <kbd>1</kbd> .. <kbd>0</kbd> | Switch to Workspace 1–10 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> .. <kbd>0</kbd> | Move Active Window to Workspace 1–10 |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Toggle Special Scratchpad Workspace |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Move Window to Special Workspace |
| <kbd>Super</kbd> + <kbd>Scroll</kbd> | Cycle through workspaces |
| <kbd>Super</kbd> + <kbd>LMB Drag</kbd> | Move floating window |
| <kbd>Super</kbd> + <kbd>RMB Drag</kbd> | Resize window |

### Screenshots

| Shortcut | Mode |
| :--- | :--- |
| <kbd>Print</kbd> | Smart selection screenshot |
| <kbd>Shift</kbd> + <kbd>Print</kbd> | Region selection screenshot |
| <kbd>Ctrl</kbd> + <kbd>Print</kbd> | Fullscreen screenshot |
| <kbd>Alt</kbd> + <kbd>Print</kbd> | Active window screenshot |

---

## 📁 Repository Structure

```text
~/.local/share/chezmoi/
├── dot_config/
│   ├── hypr/
│   │   ├── hyprland.lua                 # Root Lua configuration entry point
│   │   ├── hyprlock.conf                # Catppuccin Mocha lockscreen
│   │   ├── colors/
│   │   │   ├── mocha.lua                # Lua Catppuccin palette table
│   │   │   └── mocha.conf               # Legacy palette definition
│   │   ├── modules/                     # Modular Lua components
│   │   │   ├── monitors.lua             # Output geometry & persistent workspaces
│   │   │   ├── my_programs.lua          # Preferred applications
│   │   │   ├── env.lua                  # Environment variables
│   │   │   ├── autostart.lua            # Daemons & display initialization
│   │   │   ├── look_and_feel.lua        # Window borders, gaps, blur, shadows
│   │   │   ├── animations.lua           # Bezier curves & motion settings
│   │   │   ├── layout.lua               # Dwindle & Master layout rules
│   │   │   ├── input.lua                # Mouse, keyboard, and gestures
│   │   │   ├── window_rules.lua         # Window & layer rules (blur)
│   │   │   └── keybinds.lua             # Complete keybinding maps
│   │   └── scripts/
│   │       ├── executable_powermenu.sh  # Dynamic margin wlogout launcher
│   │       ├── executable_lock.sh       # Multi-locker wrapper script
│   │       └── executable_hyte_y70_display.sh # Automated chassis tiling script
│   ├── waybar/
│   │   ├── config.jsonc                 # Top bar layout & power module
│   │   ├── style.css                    # Catppuccin stylesheet
│   │   └── colors.css                   # Waybar color variables
│   ├── wlogout/
│   │   ├── layout                       # Actions, labels, and hotkeys
│   │   ├── style.css                    # Frosted glass card styles
│   │   └── icons/                       # Custom vector SVGs (lock, power, etc.)
│   ├── rofi/                            # Application launcher & powermenu
│   ├── kitty/                           # Kitty terminal theme and config
│   ├── swaync/                          # Notification daemon stylesheet
│   └── btop/                            # System monitor theme & config
├── dot_zshrc                            # Shell aliases & configuration
├── dot_gitconfig                        # Git user configuration
└── packages.txt                         # System dependency manifest
```

---

## 📥 Installation

These dotfiles are managed with [**chezmoi**](https://www.chezmoi.io).

### 1. Install Chezmoi & Git

```bash
sudo pacman -S --needed git chezmoi
```

### 2. Initialize & Apply Dotfiles

```bash
chezmoi init --apply https://github.com/Xoviax/dotfiles.git
```

### 3. Install Required Packages

A full package manifest is included in `packages.txt`:

```bash
sudo pacman -S --needed - < ~/packages.txt
```

### 4. Verify Configuration

You can verify the Hyprland Lua configuration at any time without restarting:

```bash
Hyprland --verify-config
```

---

## 🔄 Switching Between Lua and Legacy Hyprlang

All original `.conf` files are maintained as fallbacks. 
- **To use Lua** (Default): Ensure [`hyprland.lua`](file:///home/xoviax/.config/hypr/hyprland.lua) exists in `~/.config/hypr/`.
- **To revert to Hyprlang**: Simply rename or remove `hyprland.lua`, and Hyprland will automatically load [`hyprland.conf`](file:///home/xoviax/.config/hypr/hyprland.conf).

---

<div align="center">
  <sub>Maintained by <b><a href="https://github.com/Xoviax">Rayn Yorobe (@Xoviax)</a></b></sub>
</div>

# Caelestia Hyprland Rice & Dotfiles

A sleek, glassy, and dynamic Arch Linux desktop environment powered by **Hyprland** (Lua configuration) and **Caelestia Shell** (Quickshell/QML), featuring automatic wallpaper-driven Material You color generation and resource-efficient performance tuning for integrated graphics.

---

## 🎨 Overview

- **OS**: [Arch Linux](https://archlinux.org/)
- **Window Manager**: [Hyprland](https://hyprland.org/) (`v0.57+`, Lua configuration)
- **Desktop Shell**: [Caelestia](https://github.com/caelestia-dots/caelestia) (Bar, Dashboard, Lockscreen, Notifications, OSD)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Shell**: [Zsh](https://www.zsh.org/) + [Starship](https://starship.rs/) prompt
- **Fetch**: [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Audio Visualizer**: [Cava](https://github.com/karlstav/cava)
- **Process Monitor**: [btop](https://github.com/aristocratos/btop)
- **Launchers**: Caelestia Launcher / [Rofi-wayland](https://github.com/lbonn/rofi) / [Fuzzel](https://codeberg.org/dnkl/fuzzel)
- **Color Engine**: Wallpaper-reactive palette generated via Caelestia & Matugen

---

## ⌨️ Keybindings

| Keybinding | Action |
| --- | --- |
| `Super + Return` / `Super + Q` | Open Kitty Terminal |
| `Super + Space` | Toggle Caelestia Application Launcher |
| `Super + R` | Open Rofi App Launcher |
| `Super + Tab` | Window Switcher |
| `Super + D` | Open Caelestia Dashboard (Media, Calendar, Perf) |
| `Super + Shift + T` | Open Dashboard Tasks |
| `Super + Shift + D` | Open Screen Time Tracker |
| `Super + N` | Notification Center & Quick Settings Sidebar |
| `Super + U` | Utilities Panel |
| `Super + Escape` | Session / Power Menu |
| `Super + L` | Lock Screen |
| `Super + Shift + V` | Clipboard History |
| `Super + Period` | Emoji Picker |
| `Super + Shift + W` | Cycle Wallpaper & Auto-Regenerate Color Theme |
| `Super + B` | Open Brave Browser |
| `Super + E` | Open Nautilus File Manager |
| `Super + T` | Open Telegram Desktop |

---

## 📂 Repository Structure

```text
.
├── .config/
│   ├── hypr/             # Hyprland lua config (look, autostart, binds, rules)
│   ├── caelestia/        # Caelestia shell, CLI and theme hooks
│   ├── kitty/            # Kitty terminal configuration
│   ├── fastfetch/        # Fastfetch configuration
│   ├── fuzzel/           # Fuzzel launcher configuration
│   ├── rofi/             # Rofi theme and bindings
│   ├── cava/             # Cava visualizer config
│   ├── btop/             # btop configuration and themes
│   ├── environment.d/    # User session environment variables
│   ├── gtk-3.0/          # GTK3 styling and bookmarks
│   ├── gtk-4.0/          # GTK4 styling
│   ├── qt6ct/            # Qt6 configuration tool settings
│   ├── brave-flags.conf  # Hardware accelerated Wayland flags for Chromium/Brave
│   └── starship.toml     # Starship prompt configuration
├── scripts/              # System installation & optimization scripts
├── wallpapers/           # Wallpapers
├── .zshenv               # Zsh environment paths
├── .zshrc                # Zsh configuration, aliases, and completion
└── install.sh            # Symlinks dotfiles into ~/.config
```

---

## 🚀 Setup & Installation

### 1. Clone the repository
```bash
git clone https://github.com/amuif/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Deploy configs
```bash
./install.sh
```

### 3. Dependencies & Package Installation
The `scripts/` directory contains install helpers:
- `scripts/rice-install.sh`: Pacman & AUR packages (Hyprland, Caelestia, fonts, tools)
- `scripts/apply-ram-optimizations.sh`: ZRAM and kernel sysctl optimizations

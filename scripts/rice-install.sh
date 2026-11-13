#!/usr/bin/env bash
# Rice install: Caelestia (Quickshell) + wallpaper-driven theming
set -e

echo "==> Syncing and installing repo packages"
sudo pacman -Syu --needed --noconfirm \
  rofi zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship fastfetch \
  playerctl brightnessctl wl-clipboard cliphist hypridle hyprlock hyprpicker \
  xdg-desktop-portal-gtk qt5-wayland qt6-wayland qt6ct kvantum nwg-look adw-gtk-theme papirus-icon-theme \
  ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
  pavucontrol matugen bluez-utils power-profiles-daemon networkmanager \
  fish swappy fuzzel gpu-screen-recorder dart-sass ddcutil aubio libqalculate lm_sensors \
  qt6-imageformats qt6-shadertools cmake ninja

echo "==> Installing AUR packages (quickshell-git builds from source, takes a few minutes)"
yay -S --needed --noconfirm --answerdiff None --answerclean None \
  caelestia-shell caelestia-cli bibata-cursor-theme

echo "==> Enabling services"
sudo systemctl enable --now power-profiles-daemon bluetooth

echo
echo "==> Done. Go back to Claude and say 'done'."

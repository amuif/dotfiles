#!/usr/bin/env bash
set -e
sudo pacman -S --needed --noconfirm nautilus gvfs gvfs-mtp gvfs-gphoto2 sushi ffmpegthumbnailer
xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.default-applications.terminal exec kitty
echo "==> Default for folders: $(xdg-mime query default inode/directory)"
read -rp "Also remove Dolphin? [y/N] " a
[[ "$a" =~ ^[Yy]$ ]] && sudo pacman -Rns --noconfirm dolphin
echo "==> Done. Tell Claude 'done'."

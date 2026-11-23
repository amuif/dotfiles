#!/usr/bin/env bash
set -e
sudo pacman -S --needed --noconfirm nautilus gvfs gvfs-mtp gvfs-gphoto2 sushi ffmpegthumbnailer file-roller unrar
xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search
# libarchive (Nautilus "Extract Here") cannot do RAR VM filters; file-roller uses unrar
xdg-mime default org.gnome.FileRoller.desktop application/vnd.rar application/x-rar
gsettings set org.gnome.desktop.default-applications.terminal exec kitty
echo "==> Default for folders: $(xdg-mime query default inode/directory)"
read -rp "Also remove Dolphin? [y/N] " a
[[ "$a" =~ ^[Yy]$ ]] && sudo pacman -Rns --noconfirm dolphin
echo "==> Done. Tell Claude 'done'."

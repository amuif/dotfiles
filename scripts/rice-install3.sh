#!/usr/bin/env bash
set -e
U=$(whoami)
cd ~/.cache/yay/sddm-caelestia-sddm-git

echo "==> Installing SDDM theme + deps"
sudo pacman -S --needed --noconfirm qt6-5compat qt6-multimedia qt6-svg ttf-roboto
sudo pacman -U --noconfirm caelestia-sddm-locklike-git-*.pkg.tar.zst

echo "==> Allowing wallpaper sync to the login screen (one script only)"
echo "$U ALL=(root) NOPASSWD: /usr/share/sddm/themes/caelestia/scripts/sync.sh" | sudo tee /etc/sudoers.d/caelestia-sddm-sync >/dev/null
sudo chmod 440 /etc/sudoers.d/caelestia-sddm-sync
sudo visudo -cf /etc/sudoers.d/caelestia-sddm-sync
sudo /usr/share/sddm/themes/caelestia/scripts/sync.sh || echo "(first sync failed - tell Claude)"

echo "==> Switching login shell to zsh"
chsh -s /usr/bin/zsh

echo "==> Done. Tell Claude 'done'."

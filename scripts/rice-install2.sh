#!/usr/bin/env bash
set -e
cd ~/.cache/yay
sudo pacman -U --needed --noconfirm \
  caelestia-cli/caelestia-cli-1.1.3-1-any.pkg.tar.zst \
  caelestia-shell/caelestia-shell-2.5.0-1-x86_64.pkg.tar.zst \
  bibata-cursor-theme/bibata-cursor-theme-2.0.7-1-any.pkg.tar.zst
sudo systemctl enable --now power-profiles-daemon bluetooth
echo "==> Done. Tell Claude 'done'."

#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh — turn a fresh Arch Linux install into the full Caelestia rice
#                + dev environment (gh, node/fnm, bun, rust, go, php/composer).
#
# Run on the NEW machine, as your normal user (NOT root), after archinstall:
#     sudo pacman -S --needed git
#     git clone https://github.com/amuif/dotfiles.git ~/dotfiles
#     ~/dotfiles/bootstrap.sh
#
# Safe to re-run: every step uses --needed / checks before acting.
# Run a single step:   ./bootstrap.sh gh        (see STEPS at the bottom)
# ==============================================================================
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/bootstrap-$(date +%Y%m%d-%H%M%S).log"
FAILED=()

c() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
pkgs() { grep -vE '^\s*(#|$)' "$1"; }

# ------------------------------------------------------------------ preflight
preflight() {
  [[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root."; exit 1; }
  [[ -f /etc/arch-release ]] || { echo "This script is for Arch Linux."; exit 1; }
  ping -c1 -W3 archlinux.org >/dev/null 2>&1 || { echo "No internet. Connect first (nmtui / iwctl)."; exit 1; }
  sudo -v || exit 1
  # keep sudo alive for the whole run (AUR builds take a while)
  while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
}

# ------------------------------------------------------------------ 1. base
base() {
  c "Updating system + base tools"
  # parallel downloads + colour
  sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/; s/^#Color/Color/' /etc/pacman.conf
  sudo pacman -Syu --needed --noconfirm base-devel git
}

# ------------------------------------------------------------------ 2. drivers
drivers() {
  c "Detecting CPU / GPU drivers"
  local d=()
  grep -q GenuineIntel /proc/cpuinfo && d+=(intel-ucode)
  grep -q AuthenticAMD /proc/cpuinfo && d+=(amd-ucode)
  local gpu; gpu="$(lspci 2>/dev/null | grep -Ei 'vga|3d|display')"
  echo "$gpu"
  grep -qi intel  <<<"$gpu" && d+=(mesa vulkan-intel intel-media-driver libva-intel-driver vpl-gpu-rt)
  grep -qiE 'amd|ati|radeon' <<<"$gpu" && d+=(mesa vulkan-radeon libva-mesa-driver)
  if grep -qi nvidia <<<"$gpu"; then
    d+=(nvidia-open-dkms nvidia-utils libva-nvidia-driver linux-headers)
    warn "NVIDIA detected: also add 'nvidia_drm.modeset=1' to your kernel cmdline if archinstall didn't."
  fi
  ((${#d[@]})) && sudo pacman -S --needed --noconfirm "${d[@]}"
  # microcode needs the initramfs/bootloader to pick it up
  sudo mkinitcpio -P >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------ 3. yay
yay_install() {
  have yay && { echo "yay already installed"; return; }
  c "Installing yay (AUR helper)"
  local t; t="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin"
  (cd "$t/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$t"
}

# ------------------------------------------------------------------ 4. packages
packages() {
  c "Installing repo packages ($(pkgs "$DOTFILES/packages/pacman.txt" | wc -l))"
  sudo pacman -S --needed --noconfirm $(pkgs "$DOTFILES/packages/pacman.txt")
}

aur() {
  c "Installing AUR packages (quickshell-git compiles — takes a few minutes)"
  yay -S --needed --noconfirm --answerdiff None --answerclean None \
    $(pkgs "$DOTFILES/packages/aur.txt")
}

# ------------------------------------------------------------------ 5. dotfiles
dotfiles() {
  c "Linking dotfiles"
  bash "$DOTFILES/install.sh"

  mkdir -p "$HOME/.local/bin"
  ln -sfn "$DOTFILES/scripts/caelestia-wall-random" "$HOME/.local/bin/caelestia-wall-random"
  ln -sfn caelestia-wall-random "$HOME/.local/bin/wall-random"
  ln -sfn caelestia-wall-random "$HOME/.local/bin/wallpaper-random"
  chmod +x "$DOTFILES/scripts/"* 2>/dev/null || true

  xdg-user-dirs-update 2>/dev/null || true

  # Defaults: Nautilus for folders, kitty as terminal
  xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search 2>/dev/null || true
  gsettings set org.gnome.desktop.default-applications.terminal exec kitty 2>/dev/null || true

  # Monitor sanity check: hypr/modules/monitors.lua is tuned for a 2560x1440 panel
  local m; m="$(cat /sys/class/drm/card*-eDP-*/modes 2>/dev/null | head -1)"
  if [[ -n "$m" && "$m" != "2560x1440" ]]; then
    warn "Laptop panel here is $m, but monitors.lua sets eDP-1 to 2560x1440 @ scale 2."
    warn "Edit ~/.config/hypr/modules/monitors.lua (e.g. mode=\"preferred\", scale=\"auto\")."
  fi
}

# ------------------------------------------------------------------ 6. shell
shell() {
  c "Setting zsh as login shell"
  [[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]] || chsh -s /usr/bin/zsh
}

# ------------------------------------------------------------------ 7. GitHub
gh_setup() {
  c "GitHub CLI + git"
  if ! gh auth status >/dev/null 2>&1; then
    echo "A browser/device code login will start now."
    gh auth login --hostname github.com --git-protocol https --web --scopes "admin:public_key,read:org,repo,gist" </dev/tty >/dev/tty 2>&1
  fi
  gh auth setup-git
  gh config set git_protocol https
  gh alias set co 'pr checkout' --clobber >/dev/null 2>&1 || true

  # git identity
  [[ -z "$(git config --global user.name)" ]] && git config --global user.name "$(gh api user -q .login)"
  if [[ -z "$(git config --global user.email)" ]]; then
    read -rp "git email (Enter = GitHub noreply address): " email
    [[ -z "$email" ]] && email="$(gh api user -q '"\(.id)+\(.login)@users.noreply.github.com"')"
    git config --global user.email "$email"
  fi
  git config --global init.defaultBranch main
  git config --global pull.rebase false

  # SSH key (new key per machine — never copy private keys around in a repo)
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519" -N ""
    gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(cat /etc/hostname 2>/dev/null || echo arch)" || \
      warn "Could not upload SSH key — run: gh ssh-key add ~/.ssh/id_ed25519.pub"
  fi
  ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null; sort -u -o "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts"

  # Neovim config lives in its own repo
  if [[ ! -d "$HOME/.config/nvim/.git" ]]; then
    [[ -e "$HOME/.config/nvim" ]] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
    gh repo clone amuif/nvim "$HOME/.config/nvim"
  fi
}

# ------------------------------------------------------------------ 8. dev toolchains
dev() {
  c "Dev toolchains & apps (scripts/install-apps.sh)"
  mkdir -p "$HOME/go"
  bash "$DOTFILES/scripts/install-apps.sh" node bun php rust neovim lazygit docker herdr telegram brave claude agy
}

# ------------------------------------------------------------------ 9. system tuning
system() {
  c "Services, networking, login screen, ZRAM"

  # NetworkManager with iwd backend (what the Caelestia bar's Wi-Fi expects)
  sudo mkdir -p /etc/NetworkManager/conf.d
  printf '[device]\nwifi.backend=iwd\n'      | sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf >/dev/null
  printf '[connection]\nwifi.powersave = 2\n' | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf >/dev/null
  # switched at next reboot so we don't drop the connection mid-install
  sudo systemctl disable systemd-networkd.service systemd-networkd.socket 2>/dev/null || true
  sudo systemctl disable wpa_supplicant.service 2>/dev/null || true
  sudo systemctl enable iwd NetworkManager

  sudo systemctl enable bluetooth power-profiles-daemon fstrim.timer systemd-timesyncd

  # SDDM + Caelestia login theme
  sudo mkdir -p /etc/sddm.conf.d
  sudo tee /etc/sddm.conf.d/caelestia.conf >/dev/null <<'EOF'
[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1,QT_QPA_PLATFORM=xcb

[Theme]
Current=caelestia
EOF
  local sync=/usr/share/sddm/themes/caelestia/scripts/sync.sh
  if [[ -x $sync ]]; then
    echo "$USER ALL=(root) NOPASSWD: $sync" | sudo tee /etc/sudoers.d/caelestia-sddm-sync >/dev/null
    sudo chmod 440 /etc/sudoers.d/caelestia-sddm-sync
    sudo visudo -cf /etc/sudoers.d/caelestia-sddm-sync >/dev/null
  fi
  # disable any other display manager archinstall may have enabled
  for dm in gdm lightdm ly greetd; do sudo systemctl disable "$dm" 2>/dev/null || true; done
  sudo systemctl enable sddm

  # ZRAM + swappiness tuning
  sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram
compression-algorithm = zstd
EOF
  sudo tee /etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
vm.swappiness = 180
vm.page-cluster = 0
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
EOF
  sudo sysctl --system >/dev/null

  # user services: random wallpaper timer (dunst stays masked — Caelestia does notifications)
  systemctl --user daemon-reload
  systemctl --user enable caelestia-wallpaper-random.timer 2>/dev/null || true
  systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
}

# ------------------------------------------------------------------ 10. finish
finish() {
  c "Things this script can't do for you"
  cat <<'EOF'
  • Log in to the apps: claude, agy, Telegram, Brave sync.
  • Data partitions: scripts/setup-automount.sh has the OLD machine's NTFS UUIDs —
    edit the UUIDs (lsblk -f) before running it with sudo.
  • Copy over anything personal: ~/Projects, ~/Documents, browser profiles, Telegram login.
  • Reboot → pick Hyprland in SDDM → Super+Shift+W regenerates the colour theme.
EOF
}

# ------------------------------------------------------------------ runner
STEPS=(base drivers yay_install packages aur dotfiles shell gh_setup dev system finish)

run() {
  local s=$1
  if "$s"; then :; else FAILED+=("$s"); warn "step '$s' failed — continuing (re-run: $0 $s)"; fi
}

main() {
  preflight
  if (($#)); then for s in "$@"; do run "$s"; done
  else for s in "${STEPS[@]}"; do run "$s"; done; fi

  if ((${#FAILED[@]})); then
    warn "Failed steps: ${FAILED[*]}   (log: $LOG)"
    exit 1
  fi
  c "All done. Log: $LOG — reboot now."
}

main "$@" 2>&1 | tee "$LOG"

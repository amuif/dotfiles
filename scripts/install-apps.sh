#!/usr/bin/env bash
# ==============================================================================
# install-apps.sh — dev tools & apps for Arch Linux
#
#   ./install-apps.sh                 # install everything
#   ./install-apps.sh node rust       # only the ones you name
#   ./install-apps.sh --list          # show available names
#
# Apps: node bun php rust neovim lazygit docker herdr brave telegram claude agy
# Safe to re-run: installs are --needed and checked before acting.
# ==============================================================================
set -uo pipefail

APPS=(node bun php rust neovim lazygit docker herdr brave telegram claude agy)
FAILED=()

c()    { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
pac()  { sudo pacman -S --needed --noconfirm "$@"; }

ensure_yay() {
  have yay && return
  c "Installing yay (needed for AUR packages)"
  pac base-devel git
  local t; t="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin" &&
    (cd "$t/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$t"
}
aur() { ensure_yay && yay -S --needed --noconfirm --answerdiff None --answerclean None "$@"; }

# ------------------------------------------------------------------ apps
node() {
  c "Node.js LTS via fnm"
  pac fnm
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  fnm use lts-latest
  npm install -g npm
  echo "node $(command node -v) · npm $(npm -v)"
  grep -q 'fnm env' "$HOME/.zshrc" 2>/dev/null ||
    echo 'eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"' >> "$HOME/.zshrc"
}

bun() {
  c "Bun"
  pac bun
  echo "bun $(command bun -v)"
}

php() {
  c "PHP + Composer"
  pac php php-gd php-intl php-sqlite php-pgsql composer unzip
  local ini=/etc/php/php.ini
  for ext in bcmath curl gd iconv intl mysqli pdo_mysql pdo_pgsql pdo_sqlite pgsql sodium sqlite3 zip; do
    sudo sed -i "s/^;extension=${ext}$/extension=${ext}/" "$ini"
  done
  echo "php $(command php -r 'echo PHP_VERSION;') · $(composer -V 2>/dev/null | head -1)"
}

rust() {
  c "Rust via rustup"
  pac rustup
  rustup default stable
  rustup component add rust-analyzer clippy rustfmt
  rustc -V
}

neovim() {
  c "Neovim + what plugins / LSPs / Telescope need"
  pac neovim git gcc make unzip ripgrep fd wl-clipboard tree-sitter-cli luarocks
  if [[ ! -d "$HOME/.config/nvim/.git" ]]; then
    if have gh && gh auth status >/dev/null 2>&1; then
      [[ -e "$HOME/.config/nvim" ]] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
      gh repo clone amuif/nvim "$HOME/.config/nvim"
    else
      git clone https://github.com/amuif/nvim.git "$HOME/.config/nvim" ||
        warn "Could not clone amuif/nvim — log in with 'gh auth login' and re-run: $0 neovim"
    fi
  fi
  # install plugins headless so first launch is instant
  command nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  command nvim --version | head -1
}

lazygit() {
  c "lazygit"
  pac lazygit
  grep -q "alias lg=" "$HOME/.zshrc" 2>/dev/null || echo "alias lg='lazygit'" >> "$HOME/.zshrc"
  command lazygit --version | cut -d, -f4
}

docker() {
  c "Docker + Compose + Buildx"
  pac docker docker-compose docker-buildx
  # socket activation: daemon starts on first `docker` command, not at boot
  sudo systemctl enable --now docker.socket
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    warn "Added $USER to the 'docker' group — log out/in (or reboot) to use docker without sudo."
  fi
  have lazydocker || aur lazydocker-bin || true
  command docker --version
}

herdr() {
  c "Herdr (official installer → ~/.local/bin)"
  pac curl tar
  curl -fsSL https://releases.herdr.dev/app/install.sh | sh
}

brave() {
  c "Brave (AUR: brave-bin)"
  aur brave-bin
}

telegram() {
  c "Telegram Desktop"
  pac telegram-desktop
}

claude() {
  c "Claude Code (CLI) + Claude Desktop (AUR)"
  aur claude-code claude-desktop
  command claude --version 2>/dev/null || true
  echo "Run 'claude' once to log in."
}

agy() {
  c "Antigravity CLI (official installer → ~/.local/bin/agy)"
  pac curl tar
  if [[ -x "$HOME/.local/bin/agy" ]]; then
    echo "agy already installed (it self-updates)."
  else
    curl -fsSL https://antigravity.google/cli/install.sh | bash
  fi
}

# ------------------------------------------------------------------ runner
main() {
  [[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root."; exit 1; }
  [[ "${1:-}" == "--list" ]] && { printf '%s\n' "${APPS[@]}"; exit 0; }
  sudo -v || exit 1
  while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

  local todo=("$@"); ((${#todo[@]})) || todo=("${APPS[@]}")
  sudo pacman -Sy >/dev/null

  for a in "${todo[@]}"; do
    if [[ " ${APPS[*]} " != *" $a "* ]]; then warn "unknown app '$a' (try --list)"; FAILED+=("$a"); continue; fi
    "$a" || { FAILED+=("$a"); warn "'$a' failed — re-run: $0 $a"; }
  done

  echo
  if ((${#FAILED[@]})); then warn "Failed: ${FAILED[*]}"; exit 1; fi
  c "Done: ${todo[*]}"
  echo "Open a new terminal so PATH changes apply."
}

main "$@"

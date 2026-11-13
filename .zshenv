# ~/.zshenv: Sourced for all zsh shells (interactive, non-interactive, scripts)

typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/fnm/aliases/default/bin"
  "$HOME/.bun/bin"
  "$HOME/.cargo/bin"
  "$HOME/.config/composer/vendor/bin"
  $path
)
export PATH

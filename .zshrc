# ---- History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_all_dups hist_ignore_space share_history extended_history inc_append_history

# ---- Options
setopt autocd interactive_comments no_beep correct
bindkey -e
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ---- Completion
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ---- Wallpaper colours for new terminals (caelestia)
[[ -f ~/.local/state/caelestia/sequences.txt ]] && cat ~/.local/state/caelestia/sequences.txt

# ---- Aliases
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias v='nvim'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias update='yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias hconf='nvim ~/.config/hypr/'
alias wall='caelestia wallpaper -r'
alias ff='fastfetch'

export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"

# ---- Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- Prompt
eval "$(starship init zsh)"

# ---- Greeting (only in interactive kitty windows, not nested shells)
[[ -o interactive && $SHLVL -le 2 && -z "$NVIM" ]] && fastfetch

# ---- Dev toolchains
# Node via fnm (auto-switches version when a folder has .nvmrc / .node-version)
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
# Rust (rustup/cargo)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
# Bun global installs
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
# PHP 7.4: `php74` is the binary; composer74 runs Composer with it
command -v php74 >/dev/null && alias composer74='php74 /usr/bin/composer'
export PATH="$HOME/.config/composer/vendor/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/amuif/.local/bin:$PATH"

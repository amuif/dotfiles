#!/usr/bin/env bash
# Dotfiles installer / symlinker
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Deploying dotfiles from ${DOTFILES_DIR}"

# Create required directories
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/Pictures/Wallpapers"

# Symlink .config folders and files
for item in "${DOTFILES_DIR}/.config"/*; do
    base="$(basename "$item")"
    target="${HOME}/.config/${base}"
    
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up existing ${target} -> ${target}.bak"
        mv "$target" "${target}.bak"
    fi
    
    echo "Linking .config/${base} -> ${target}"
    ln -sfn "$item" "$target"
done

# Symlink shell files
for file in .zshrc .zshenv; do
    if [ -f "${DOTFILES_DIR}/${file}" ]; then
        target="${HOME}/${file}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "Backing up ${target} -> ${target}.bak"
            mv "$target" "${target}.bak"
        fi
        echo "Linking ${file} -> ${target}"
        ln -sfn "${DOTFILES_DIR}/${file}" "$target"
    fi
done

# Copy default wallpaper
if [ -d "${DOTFILES_DIR}/wallpapers" ]; then
    cp -r "${DOTFILES_DIR}/wallpapers"/* "${HOME}/Pictures/Wallpapers/" 2>/dev/null || true
fi

echo "==> Dotfiles setup completed successfully!"

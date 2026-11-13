#!/usr/bin/env bash
set -e
echo "==> Repo packages: fnm, bun, rustup, composer, build tools"
sudo pacman -S --needed --noconfirm fnm bun rustup composer unzip base-devel

echo "==> PHP 7.4 from AUR (compiles from source - this takes a while, leave it running)"
yay -S --needed --noconfirm --answerdiff None --answerclean None \
  php74 php74-cli php74-fpm php74-openssl php74-pdo php74-mysql php74-sqlite php74-pgsql \
  php74-mbstring php74-xml php74-dom php74-simplexml php74-xmlreader php74-xmlwriter \
  php74-tokenizer php74-ctype php74-json php74-curl php74-zip php74-gd php74-intl \
  php74-bcmath php74-fileinfo php74-phar php74-iconv php74-sodium php74-opcache \
  php74-exif php74-pcntl php74-posix php74-sockets

echo "==> Done. Tell Claude 'done' (or paste the error)."

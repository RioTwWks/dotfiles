#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=============================="
echo " EndeavourOS Bootstrap"
echo "=============================="

"$ROOT/scripts/install-packages.sh"
"$ROOT/scripts/configure-shell.sh"
"$ROOT/scripts/configure-kde.sh"
"$ROOT/scripts/configure-devops.sh"
"$ROOT/scripts/symlink.sh"

mkdir -p ~/.config/fastfetch
ln -sf "$ROOT/configs/fastfetch/config.jsonc" \
       ~/.config/fastfetch/config.jsonc

mkdir -p ~/.config/ghostty
ln -sf "$ROOT/configs/ghostty/config" \
       ~/.config/ghostty/config

ln -sf "$ROOT/configs/zsh/.zshrc" ~/.zshrc
ln -sf "$ROOT/configs/git/.gitconfig" ~/.gitconfig
ln -sf "$ROOT/configs/starship/starship.toml" ~/.config/starship.toml

echo
echo "Bootstrap completed."
echo "Please logout or reboot."
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config/ghostty ~/.config/fastfetch

[[ -f "$ROOT/configs/ghostty/config" ]] && \
  ln -sf "$ROOT/configs/ghostty/config" ~/.config/ghostty/config

[[ -f "$ROOT/configs/fastfetch/config.jsonc" ]] && \
  ln -sf "$ROOT/configs/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc

[[ -f "$ROOT/configs/starship/starship.toml" ]] && \
  ln -sf "$ROOT/configs/starship/starship.toml" ~/.config/starship.toml

[[ -f "$ROOT/configs/zsh/.zshrc" ]] && \
  ln -sf "$ROOT/configs/zsh/.zshrc" ~/.zshrc

[[ -f "$ROOT/configs/git/.gitconfig" ]] && \
  ln -sf "$ROOT/configs/git/.gitconfig" ~/.gitconfig

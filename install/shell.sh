#!/usr/bin/env bash
# Link configs and set zsh as login shell.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config/ghostty ~/.config/fastfetch ~/.config/Cursor/User

ln -sf "$ROOT/configs/starship/starship.toml" ~/.config/starship.toml
ln -sf "$ROOT/configs/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
ln -sf "$ROOT/configs/ghostty/config" ~/.config/ghostty/config
ln -sf "$ROOT/configs/zsh/.zshrc" ~/.zshrc
ln -sf "$ROOT/configs/git/.gitconfig" ~/.gitconfig

if [[ -f "$ROOT/configs/cursor/settings.json" ]]; then
  ln -sf "$ROOT/configs/cursor/settings.json" ~/.config/Cursor/User/settings.json
fi
if [[ -f "$ROOT/configs/cursor/keybindings.json" ]]; then
  ln -sf "$ROOT/configs/cursor/keybindings.json" ~/.config/Cursor/User/keybindings.json
fi

if [[ -x /usr/bin/zsh ]] && [[ "${SHELL:-}" != */zsh ]]; then
  chsh -s /usr/bin/zsh || true
fi

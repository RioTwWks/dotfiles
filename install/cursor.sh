#!/usr/bin/env bash
# Cursor IDE (AUR) + extensions + User settings/keybindings.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT_FILE="$ROOT/packages/cursor-extensions.txt"
USER_DIR="${HOME}/.config/Cursor/User"

if ! command -v cursor >/dev/null 2>&1; then
  if ! command -v yay >/dev/null 2>&1; then
    echo "yay required to install cursor-bin" >&2
    exit 1
  fi
  yay -S --needed --noconfirm cursor-bin
fi

mkdir -p "$USER_DIR"
[[ -f "$ROOT/configs/cursor/settings.json" ]] && \
  ln -sf "$ROOT/configs/cursor/settings.json" "$USER_DIR/settings.json"
[[ -f "$ROOT/configs/cursor/keybindings.json" ]] && \
  ln -sf "$ROOT/configs/cursor/keybindings.json" "$USER_DIR/keybindings.json"

if [[ ! -f "$EXT_FILE" ]]; then
  echo "No $EXT_FILE — skip extensions"
  exit 0
fi

mapfile -t extensions < <(grep -vE '^\s*(#|$)' "$EXT_FILE" || true)
for ext in "${extensions[@]}"; do
  echo "Installing Cursor extension: $ext"
  cursor --install-extension "$ext" || true
done

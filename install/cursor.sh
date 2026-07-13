#!/usr/bin/env bash
# Cursor IDE (AUR) + extensions from packages/cursor-extensions.txt

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT_FILE="$ROOT/packages/cursor-extensions.txt"

if ! command -v cursor >/dev/null 2>&1; then
  if ! command -v yay >/dev/null 2>&1; then
    echo "yay required to install cursor-bin" >&2
    exit 1
  fi
  yay -S --needed --noconfirm cursor-bin
fi

if [[ ! -f "$EXT_FILE" ]]; then
  echo "No $EXT_FILE — skip extensions"
  exit 0
fi

mapfile -t extensions < <(grep -vE '^\s*(#|$)' "$EXT_FILE" || true)
for ext in "${extensions[@]}"; do
  echo "Installing Cursor extension: $ext"
  cursor --install-extension "$ext" || true
done

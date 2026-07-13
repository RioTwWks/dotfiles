#!/usr/bin/env bash
# Install fonts from packages/fonts.txt

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$ROOT/packages/fonts.txt"

mapfile -t fonts < <(grep -vE '^\s*(#|$)' "$LIST" || true)
if ((${#fonts[@]})); then
  sudo pacman -S --needed --noconfirm "${fonts[@]}"
fi

echo "Set JetBrainsMono Nerd Font in System Settings → Fonts (size 10–11)."

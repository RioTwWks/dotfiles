#!/usr/bin/env bash
# Nerd Fonts + emoji for terminal / Plasma.

set -euo pipefail

sudo pacman -S --needed --noconfirm \
  ttf-jetbrains-mono-nerd \
  noto-fonts-emoji

echo "Set JetBrainsMono Nerd Font in System Settings → Fonts (size 10–11)."

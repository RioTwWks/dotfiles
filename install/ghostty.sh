#!/usr/bin/env bash
# Ghostty terminal + linked config.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

sudo pacman -S --needed --noconfirm ghostty
mkdir -p ~/.config/ghostty
ln -sf "$ROOT/configs/ghostty/config" ~/.config/ghostty/config

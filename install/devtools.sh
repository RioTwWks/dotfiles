#!/usr/bin/env bash
# Extra DevOps CLI tools beyond the base pacman list.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

sudo pacman -S --needed --noconfirm \
  go nodejs python terraform ansible kubectl helm github-cli

if command -v yay >/dev/null 2>&1; then
  # Optional: kind for local k8s; mise for version managers
  yay -S --needed --noconfirm kind mise 2>/dev/null || true
fi

echo "Devtools ready. Check with: $ROOT/scripts/doctor.sh"

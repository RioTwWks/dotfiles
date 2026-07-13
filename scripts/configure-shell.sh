#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config

ln -sf "$ROOT/configs/starship/starship.toml" ~/.config/starship.toml
ln -sf "$ROOT/configs/zsh/.zshrc" ~/.zshrc 2>/dev/null || true

if [[ -x /usr/bin/zsh ]] && [[ "${SHELL:-}" != */zsh ]]; then
  chsh -s /usr/bin/zsh || true
fi

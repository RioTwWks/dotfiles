#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mapfile -t pacman_pkgs < <(grep -vE '^\s*(#|$)' "$ROOT/packages/pacman.txt" || true)
mapfile -t aur_pkgs < <(grep -vE '^\s*(#|$)' "$ROOT/packages/aur.txt" || true)
mapfile -t flatpak_pkgs < <(grep -vE '^\s*(#|$)' "$ROOT/packages/flatpak.txt" || true)

if ((${#pacman_pkgs[@]})); then
  sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
fi

if ((${#aur_pkgs[@]})); then
  if ! command -v yay >/dev/null 2>&1; then
    echo "yay not found; skip AUR packages: ${aur_pkgs[*]}"
  else
    yay -S --needed --noconfirm "${aur_pkgs[@]}"
  fi
fi

if ((${#flatpak_pkgs[@]})); then
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak not found; skip: ${flatpak_pkgs[*]}"
  else
    flatpak install -y "${flatpak_pkgs[@]}"
  fi
fi

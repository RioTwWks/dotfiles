#!/usr/bin/env bash
# Docker engine + compose; add current user to docker group.

set -euo pipefail

sudo pacman -S --needed --noconfirm docker docker-compose
sudo systemctl enable --now docker

target_user="${SUDO_USER:-$USER}"
if [[ "$target_user" != root ]]; then
  sudo usermod -aG docker "$target_user"
  echo "Added $target_user to docker group (re-login required)."
fi

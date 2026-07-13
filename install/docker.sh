#!/usr/bin/env bash
# Docker engine + compose + daemon.json; add user to docker group.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

sudo pacman -S --needed --noconfirm docker docker-compose

if [[ -f "$ROOT/configs/docker/daemon.json" ]]; then
  sudo mkdir -p /etc/docker
  sudo cp "$ROOT/configs/docker/daemon.json" /etc/docker/daemon.json
fi

sudo systemctl enable --now docker

target_user="${SUDO_USER:-$USER}"
if [[ "$target_user" != root ]]; then
  sudo usermod -aG docker "$target_user"
  echo "Added $target_user to docker group (re-login required)."
fi

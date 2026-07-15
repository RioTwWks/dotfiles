#!/usr/bin/env bash
# Safe rolling update with optional toolchain upgrades.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

green="\033[32m"
yellow="\033[33m"
blue="\033[1;34m"
reset="\033[0m"

step() { printf "\n${blue}==>${reset} %s\n" "$1"; }

run_if() {
  local label="$1" cmd="$2"
  shift 2
  if command -v "$cmd" >/dev/null 2>&1; then
    step "$label"
    "$@"
  else
    printf "${yellow}skip${reset} %s (%s not found)\n" "$label" "$cmd"
  fi
}

echo "=============================="
echo " System update (with snapshots)"
echo "=============================="

if ! findmnt -no FSTYPE / | grep -qx btrfs; then
  printf "${yellow}Warning:${reset} root is not btrfs — no automatic snap-pac snapshots.\n"
elif [[ ! -f /etc/snapper/configs/root ]]; then
  printf "${yellow}Warning:${reset} snapper 'root' config missing.\n"
  echo "Run: $ROOT/install/snapper.sh"
fi

step "pacman -Syu"
sudo pacman -Syu --noconfirm

run_if "yay -Sua (AUR)" yay yay -Sua --noconfirm
run_if "flatpak update" flatpak flatpak update -y
run_if "rustup update" rustup rustup update
run_if "mise upgrade" mise mise upgrade
run_if "npm update -g" npm npm update -g
run_if "flutter upgrade" flutter flutter upgrade

if systemctl is-enabled grub-btrfsd.service >/dev/null 2>&1; then
  printf "${green}✓${reset} grub-btrfsd will refresh the snapshot boot menu\n"
elif [[ -d /boot/grub ]]; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

if [[ -x "$ROOT/scripts/backup.sh" ]] && [[ -f "${DOTFILES_BACKUP_ENV:-$HOME/.config/dotfiles/backup.env}" ]]; then
  step "Incremental Borg backup"
  "$ROOT/scripts/backup.sh" create update || true
fi

echo
printf "${green}Update finished.${reset}\n"
echo "List snapshots: snapper -c root list"
echo "List backups:   $ROOT/scripts/backup.sh list"
echo "Health check:   $ROOT/scripts/doctor.sh"

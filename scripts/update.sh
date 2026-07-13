#!/usr/bin/env bash
# Safe rolling update. snap-pac creates pre/post root snapshots automatically.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

green="\033[32m"
yellow="\033[33m"
reset="\033[0m"

echo "=============================="
echo " System update (with snapshots)"
echo "=============================="

if ! findmnt -no FSTYPE / | grep -qx btrfs; then
  printf "${yellow}Warning:${reset} root is not btrfs — no automatic snap-pac snapshots.\n"
elif ! snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx root; then
  printf "${yellow}Warning:${reset} snapper 'root' config missing.\n"
  echo "Run: $ROOT/install/snapper.sh"
fi

sudo pacman -Syu --noconfirm

if command -v yay >/dev/null 2>&1; then
  yay -Syu --noconfirm
fi

if command -v flatpak >/dev/null 2>&1; then
  flatpak update -y || true
fi

if systemctl is-enabled grub-btrfsd.service >/dev/null 2>&1; then
  printf "${green}✓${reset} grub-btrfsd will refresh the snapshot boot menu\n"
elif [[ -d /boot/grub ]]; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

echo
printf "${green}Update finished.${reset}\n"
echo "List snapshots: snapper -c root list"
echo "Health check:   $ROOT/scripts/doctor.sh"

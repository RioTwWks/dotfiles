#!/usr/bin/env bash
# Doctor: toolchain + Btrfs self-recovery health.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

ok()   { printf "${green}✓${reset} %s\n" "$*"; }
bad()  { printf "${red}✗${reset} %s\n" "$*"; }
warn() { printf "${yellow}!${reset} %s\n" "$*"; }

echo "──────── Toolchain ────────"
"$ROOT/scripts/devtools.sh"

echo
echo "──────── Self-recovery ────────"

if ! findmnt -no FSTYPE / | grep -qx btrfs; then
  bad "Root is not btrfs"
  exit 0
fi
ok "Root filesystem: btrfs ($(findmnt -no SOURCE /))"

if findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
  ok "/.snapshots mounted ($(findmnt -no SOURCE /.snapshots))"
else
  bad "/.snapshots not mounted"
fi

check_unit() {
  local unit="$1"
  if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
    ok "$unit enabled"
  else
    bad "$unit not enabled"
  fi
}

check_unit snapper-timeline.timer
check_unit snapper-cleanup.timer
check_unit snapper-boot.timer
check_unit grub-btrfsd.service
check_unit btrfs-scrub@-.timer

if command -v snapper >/dev/null 2>&1; then
  if snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx root; then
    count="$(snapper -c root list 2>/dev/null | awk 'NR>2' | wc -l | tr -d ' ')"
    ok "snapper root config ($count snapshots)"
  else
    bad "snapper root config missing — run install/snapper.sh"
  fi

  if findmnt -no FSTYPE /home 2>/dev/null | grep -qx btrfs; then
    if snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx home; then
      count="$(snapper -c home list 2>/dev/null | awk 'NR>2' | wc -l | tr -d ' ')"
      ok "snapper home config ($count snapshots)"
    else
      warn "snapper home config missing"
    fi
  fi
else
  bad "snapper not installed"
fi

for pkg in snap-pac grub-btrfs btrfs-assistant; do
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    ok "$pkg $(pacman -Q "$pkg" | awk '{print $2}')"
  else
    bad "$pkg not installed"
  fi
done

if [[ -f /etc/default/grub-btrfs/config ]] \
  && grep -qE '^[[:space:]]*GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=.*rd\.live\.overlay\.overlayfs=1' \
       /etc/default/grub-btrfs/config; then
  ok "grub-btrfs dracut overlay parameter set"
else
  warn "grub-btrfs dracut overlay not configured"
fi

echo
echo "Rollback: GRUB → snapshots submenu, or btrfs-assistant"
echo "Setup:    $ROOT/install/snapper.sh"
echo "Update:   $ROOT/scripts/update.sh"

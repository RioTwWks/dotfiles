#!/usr/bin/env bash
# Configure Btrfs self-recovery: Snapper + snap-pac + grub-btrfs + scrub.
# Safe to re-run. Requires root (sudo).
#
# @snapshots layout follows ArchWiki:
#   umount /.snapshots → snapper create-config → delete nested .snapshots → remount @snapshots

set -euo pipefail

ROOT_FS="$(findmnt -no FSTYPE /)"
if [[ "$ROOT_FS" != "btrfs" ]]; then
  echo "Root filesystem is $ROOT_FS, not btrfs — recovery stack skipped."
  exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo --preserve-env=SUDO_USER "$0" "$@"
fi

log() { printf '==> %s\n' "$*"; }

ROOT_SRC="$(findmnt -no SOURCE /)"
ROOT_DEV="${ROOT_SRC%%\[*}"
ROOT_UUID="$(findmnt -no UUID /)"
FSTAB="/etc/fstab"
GRUB_BTRFS_CFG="/etc/default/grub-btrfs/config"
TOP_MNT="$(mktemp -d /tmp/dotfiles-btrfs-XXXXXX)"
cleanup() { umount "$TOP_MNT" 2>/dev/null || true; rmdir "$TOP_MNT" 2>/dev/null || true; }
trap cleanup EXIT

subvol_exists() {
  local name="$1"
  btrfs subvolume list "$TOP_MNT" | awk '{print $NF}' | grep -qx "$name"
}

ensure_snapshots_subvol() {
  log "Ensuring @snapshots subvolume and fstab entry"
  mount -o subvolid=5 "$ROOT_DEV" "$TOP_MNT"

  if ! subvol_exists '@snapshots'; then
    btrfs subvolume create "$TOP_MNT/@snapshots"
  fi

  if ! grep -qE '[[:space:]]/\.snapshots[[:space:]]' "$FSTAB"; then
    cat >>"$FSTAB" <<EOF
UUID=$ROOT_UUID /.snapshots    btrfs   subvol=/@snapshots,noatime,compress=zstd 0 0
EOF
  fi

  systemctl daemon-reload
}

# ArchWiki workaround: create-config cannot run while @snapshots is mounted at /.snapshots
create_root_config() {
  if snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx root; then
    log "Snapper config 'root' already exists"
    if ! findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
      mkdir -p /.snapshots
      mount /.snapshots
    fi
    return
  fi

  log "Creating snapper config 'root' (ArchWiki @snapshots dance)"

  # Stop any systemd mount unit for /.snapshots so it cannot recreate the path.
  systemctl stop "$(systemd-escape -p --suffix=mount /.snapshots)" 2>/dev/null || true

  if findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
    umount /.snapshots
  fi

  # snapper create-config requires that /.snapshots does NOT exist yet.
  # A leftover empty directory from a previous run causes:
  #   "creating btrfs subvolume .snapshots failed since it already exists"
  if [[ -e /.snapshots ]]; then
    if btrfs subvolume show /.snapshots >/dev/null 2>&1; then
      btrfs subvolume delete /.snapshots
    else
      rmdir /.snapshots 2>/dev/null || rm -rf /.snapshots
    fi
  fi

  if [[ -e /.snapshots ]]; then
    echo "ERROR: could not remove /.snapshots before create-config" >&2
    ls -la /.snapshots >&2 || true
    exit 1
  fi

  snapper -c root create-config /

  # create-config made a nested .snapshots subvolume inside @ — replace with @snapshots mount.
  systemctl stop "$(systemd-escape -p --suffix=mount /.snapshots)" 2>/dev/null || true
  if findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
    umount /.snapshots
  fi
  if btrfs subvolume show /.snapshots >/dev/null 2>&1; then
    btrfs subvolume delete /.snapshots
  elif [[ -e /.snapshots ]]; then
    rmdir /.snapshots 2>/dev/null || rm -rf /.snapshots
  fi

  mkdir -p /.snapshots
  systemctl daemon-reload
  mount /.snapshots

  if ! findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
    echo "ERROR: /.snapshots failed to mount (@snapshots)" >&2
    exit 1
  fi
}

create_home_config() {
  if ! findmnt -no FSTYPE /home 2>/dev/null | grep -qx btrfs; then
    return
  fi

  if snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx home; then
    log "Snapper config 'home' already exists"
    return
  fi

  log "Creating snapper config 'home' for /home"
  # Nested /home/.snapshots inside @home is fine (no separate subvolume needed).
  snapper -c home create-config /home
}

tune_root_config() {
  local cfg="/etc/snapper/configs/root"
  [[ -f "$cfg" ]] || return

  sed -i \
    -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' \
    -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
    -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
    -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' \
    -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
    -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
    -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="20"/' \
    -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' \
    -e 's/^ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
    -e 's/^SYNC_ACL=.*/SYNC_ACL="yes"/' \
    "$cfg"
}

tune_home_config() {
  local cfg="/etc/snapper/configs/home"
  [[ -f "$cfg" ]] || return

  sed -i \
    -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' \
    -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="3"/' \
    -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
    -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' \
    -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
    -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
    -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' \
    -e 's/^ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
    -e 's/^SYNC_ACL=.*/SYNC_ACL="yes"/' \
    "$cfg"
}

configure_grub_btrfs() {
  log "Configuring grub-btrfs for dracut read-only snapshot boots"
  mkdir -p "$(dirname "$GRUB_BTRFS_CFG")"
  touch "$GRUB_BTRFS_CFG"

  local desired='GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"'

  if grep -qE '^[[:space:]]*#?[[:space:]]*GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=' "$GRUB_BTRFS_CFG"; then
    sed -i -E 's|^[[:space:]]*#?[[:space:]]*GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=.*|'"$desired"'|' \
      "$GRUB_BTRFS_CFG"
  else
    printf '\n%s\n' "$desired" >>"$GRUB_BTRFS_CFG"
  fi
}

enable_services() {
  log "Enabling snapshot timeline, cleanup, boot hooks, grub-btrfsd, and scrub"
  systemctl enable --now snapper-timeline.timer
  systemctl enable --now snapper-cleanup.timer
  systemctl enable --now snapper-boot.timer
  systemctl enable --now grub-btrfsd.service

  systemctl enable --now btrfs-scrub@-.timer
  if findmnt -no FSTYPE /home 2>/dev/null | grep -qx btrfs; then
    systemctl enable --now btrfs-scrub@home.timer
  fi
}

initial_snapshot() {
  if snapper -c root list 2>/dev/null | awk 'NR>2 {found=1} END{exit !found}'; then
    log "Root snapshots already present — skipping initial snapshot"
    return
  fi
  log "Creating initial root snapshot"
  snapper -c root create --description "dotfiles initial recovery baseline" --cleanup-algorithm number
}

refresh_grub() {
  if [[ -d /boot/grub ]]; then
    log "Refreshing GRUB config (snapshot submenu)"
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
}

log "Configuring EndeavourOS Btrfs self-recovery"
ensure_snapshots_subvol
create_root_config
create_home_config
tune_root_config
tune_home_config
configure_grub_btrfs
enable_services
initial_snapshot
refresh_grub

log "Recovery stack ready."
echo
echo "Rollback:"
echo "  1. GRUB → \"EndeavourOS snapshots\" → boot a snapshot"
echo "  2. Or open Btrfs Assistant and restore a snapper snapshot"
echo "  3. Health check:  ~/dotfiles/scripts/versions.sh"

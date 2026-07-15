#!/usr/bin/env bash
# EndeavourOS workstation bootstrap — idempotent, modular installers.

set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FAILED=0

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

run() {
  local title="$1"
  shift
  printf "\n${BLUE}==>${RESET} %s\n" "$title"
  if "$@"; then
    printf "    ${GREEN}✓ done${RESET}\n"
  else
    printf "    ${RED}✗ failed${RESET}\n"
    FAILED=$((FAILED + 1))
  fi
}

echo "=============================="
echo " EndeavourOS Workstation"
echo "=============================="
echo "Root: $ROOT"

run "Installing packages" \
  "$ROOT/install/packages.sh"

run "Enabling system services" \
  "$ROOT/install/services.sh"

run "Configuring shell + links" \
  "$ROOT/install/shell.sh"

run "Installing fonts" \
  "$ROOT/install/fonts.sh"

run "Installing Ghostty" \
  "$ROOT/install/ghostty.sh"

run "Installing Docker" \
  "$ROOT/install/docker.sh"

run "Installing Cursor + extensions" \
  "$ROOT/install/cursor.sh"

run "Installing DevOps tools" \
  "$ROOT/install/devtools.sh"

run "Configuring KDE" \
  "$ROOT/install/kde.sh"

run "Configuring Snapper recovery" \
  "$ROOT/install/snapper.sh"

run "Configuring incremental backups (Borg)" \
  "$ROOT/install/backup.sh"

echo
if ((FAILED == 0)); then
  printf "${GREEN}Bootstrap completed successfully.${RESET}\n"
else
  printf "${RED}Bootstrap finished with %s failed step(s).${RESET}\n" "$FAILED"
fi
echo "Doctor:  $ROOT/scripts/doctor.sh"
echo "Update:  $ROOT/scripts/update.sh"
echo "Backup:  $ROOT/scripts/backup.sh init   # first full, then auto-increment"
echo "Please logout or reboot."
exit "$FAILED"

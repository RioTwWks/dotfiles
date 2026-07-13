#!/usr/bin/env bash
# EndeavourOS workstation bootstrap — idempotent, modular installers.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FAILED=0

run() {
  local title="$1"
  shift
  echo
  echo "==> $title"
  if "$@"; then
    echo "    ✓ done"
  else
    echo "    ✗ failed"
    FAILED=$((FAILED + 1))
  fi
}

echo "=============================="
echo " EndeavourOS Workstation"
echo "=============================="
echo "Root: $ROOT"

run "Installing packages" \
  "$ROOT/install/packages.sh"

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

echo
if ((FAILED == 0)); then
  echo "Bootstrap completed successfully."
else
  echo "Bootstrap finished with $FAILED failed step(s)."
fi
echo "Doctor:  $ROOT/scripts/doctor.sh"
echo "Update:  $ROOT/scripts/update.sh"
echo "Please logout or reboot."
exit "$FAILED"

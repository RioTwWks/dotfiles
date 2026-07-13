#!/usr/bin/env bash
# Enable systemd units listed in packages/services.txt

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$ROOT/packages/services.txt"

[[ -f "$LIST" ]] || exit 0

mapfile -t units < <(grep -vE '^\s*(#|$)' "$LIST" || true)
for unit in "${units[@]}"; do
  if systemctl list-unit-files "$unit" >/dev/null 2>&1 || \
     systemctl cat "$unit" >/dev/null 2>&1; then
    echo "enable --now $unit"
    sudo systemctl enable --now "$unit" || true
  else
    echo "skip missing unit: $unit"
  fi
done

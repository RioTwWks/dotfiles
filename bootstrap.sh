#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=============================="
echo " EndeavourOS Bootstrap"
echo "=============================="

"$ROOT/scripts/install-packages.sh"
"$ROOT/scripts/configure-shell.sh"
"$ROOT/scripts/configure-kde.sh"
"$ROOT/scripts/configure-devops.sh"
"$ROOT/install/snapper.sh"
"$ROOT/scripts/symlink.sh"

echo
echo "Bootstrap completed."
echo "Recovery doctor: $ROOT/scripts/versions.sh"
echo "Please logout or reboot."

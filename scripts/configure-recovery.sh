#!/usr/bin/env bash
# Compatibility wrapper — canonical path is install/snapper.sh
exec "$(cd "$(dirname "$0")/.." && pwd)/install/snapper.sh" "$@"

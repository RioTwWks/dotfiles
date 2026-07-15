#!/usr/bin/env bash
# Incremental Borg backup: first archive seeds the repo, later ones add only changes.
#
# Usage:
#   backup.sh init              # create repo + first (full) archive
#   backup.sh create [label]    # incremental archive (default label: auto)
#   backup.sh list
#   backup.sh info
#   backup.sh prune
#   backup.sh check

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${DOTFILES_BACKUP_ENV:-$HOME/.config/dotfiles/backup.env}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LAST_FILE="$STATE_DIR/backup-last"
LOCK_FILE="$STATE_DIR/backup.lock"

blue="\033[1;34m"
green="\033[1;32m"
yellow="\033[33m"
red="\033[1;31m"
reset="\033[0m"

log()  { printf "${blue}==>${reset} %s\n" "$*"; }
ok()   { printf "${green}✓${reset} %s\n" "$*"; }
warn() { printf "${yellow}!${reset} %s\n" "$*"; }
die()  { printf "${red}✗${reset} %s\n" "$*" >&2; exit 1; }

load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    die "Missing $ENV_FILE — copy configs/backup/backup.env.example and edit it"
  fi
  # shellcheck disable=SC1090
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a

  : "${BACKUP_REPO:?BACKUP_REPO required in $ENV_FILE}"
  : "${BACKUP_PATHS:?BACKUP_PATHS required in $ENV_FILE}"
  : "${BACKUP_PREFIX:={hostname}}"
  : "${KEEP_DAILY:=7}"
  : "${KEEP_WEEKLY:=4}"
  : "${KEEP_MONTHLY:=6}"
  : "${MIN_INTERVAL_SEC:=3600}"

  export BORG_REPO="$BACKUP_REPO"
  export BORG_PASSPHRASE="${BORG_PASSPHRASE:-}"
  export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no
}

need_borg() {
  command -v borg >/dev/null 2>&1 || die "borg not installed — run install/backup.sh"
}

with_lock() {
  mkdir -p "$STATE_DIR"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    warn "Another backup is running — skip"
    exit 0
  fi
}

repo_exists() {
  [[ -d "$BACKUP_REPO" ]] || borg info "$BACKUP_REPO" >/dev/null 2>&1
}

cmd_init() {
  need_borg
  load_env
  with_lock

  if [[ -z "${BORG_PASSPHRASE:-}" || "$BORG_PASSPHRASE" == "change-me" ]]; then
    die "Set a real BORG_PASSPHRASE in $ENV_FILE before init"
  fi

  mkdir -p "$(dirname "$BACKUP_REPO")"

  if repo_exists && borg list "$BACKUP_REPO" >/dev/null 2>&1; then
    warn "Repository already exists: $BACKUP_REPO"
  else
    log "Initializing Borg repo at $BACKUP_REPO"
    borg init --encryption=repokey-blake2 "$BACKUP_REPO"
    ok "Repository created"
  fi

  cmd_create "initial-full"
}

should_skip_auto() {
  local mode="${1:-}"
  [[ "$mode" != "auto" && "$mode" != "pacman" && "$mode" != "timer" ]] && return 1
  [[ ! -f "$LAST_FILE" ]] && return 1
  local last now
  last=$(<"$LAST_FILE")
  now=$(date +%s)
  if (( now - last < MIN_INTERVAL_SEC )); then
    warn "Last backup $((now - last))s ago (< ${MIN_INTERVAL_SEC}s) — skip auto"
    return 0
  fi
  return 1
}

cmd_create() {
  need_borg
  load_env
  with_lock

  local label="${1:-manual}"
  if should_skip_auto "$label"; then
    exit 0
  fi

  repo_exists || die "Repo missing — run: $ROOT/scripts/backup.sh init"

  local stamp archive
  stamp=$(date +%Y-%m-%dT%H:%M:%S)
  archive="${BACKUP_PREFIX}-${label}-${stamp}"

  # shellcheck disable=SC2206
  local paths=( $BACKUP_PATHS )
  local exclude_file="$ROOT/configs/backup/excludes.txt"
  local -a args=(
    create
    --verbose
    --stats
    --compression zstd,3
    --exclude-caches
  )

  if [[ -f "$exclude_file" ]]; then
    args+=(--exclude-from "$exclude_file")
  fi

  log "Creating archive $archive"
  log "Paths: ${paths[*]}"
  borg "${args[@]}" "::$archive" "${paths[@]}"

  date +%s >"$LAST_FILE"
  ok "Backup done: $archive"
  ok "Repo grows incrementally — only changed chunks are stored"
}

cmd_list() {
  need_borg
  load_env
  borg list
}

cmd_info() {
  need_borg
  load_env
  borg info
}

cmd_prune() {
  need_borg
  load_env
  with_lock
  log "Pruning old archives"
  borg prune \
    --list \
    --keep-daily="$KEEP_DAILY" \
    --keep-weekly="$KEEP_WEEKLY" \
    --keep-monthly="$KEEP_MONTHLY"
  borg compact
  ok "Prune complete"
}

cmd_check() {
  need_borg
  load_env
  log "Checking repository integrity"
  borg check --verify-data
  ok "Check complete"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

  init              Create Borg repo + first full archive
  create [label]    Incremental archive (labels: manual|auto|pacman|timer|…)
  list              List archives
  info              Repository info
  prune             Apply retention policy
  check             Verify repository

Config: $ENV_FILE
EOF
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    init)   cmd_init "$@" ;;
    create) cmd_create "${1:-manual}" ;;
    list)   cmd_list ;;
    info)   cmd_info ;;
    prune)  cmd_prune ;;
    check)  cmd_check ;;
    -h|--help|help|"") usage ;;
    *) die "Unknown command: $cmd" ;;
  esac
}

main "$@"

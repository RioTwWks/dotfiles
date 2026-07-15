#!/usr/bin/env bash
# Workstation doctor: full health-check after bootstrap / recovery.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

ok()   { printf "${green}✓${reset} %s\n" "$*"; }
bad()  { printf "${red}✗${reset} %s\n" "$*"; }
warn() { printf "${yellow}!${reset} %s\n" "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

check_cmd() {
  local label="$1" cmd="$2" version=""
  if ! have_cmd "$cmd"; then
    bad "$label"
    return
  fi
  case "$cmd" in
    docker)    version=$(docker --version 2>/dev/null | awk '{print $3; exit}' | tr -d ',') ;;
    git)       version=$(git --version 2>/dev/null | awk '{print $3; exit}') ;;
    yay)       version=$(yay --version 2>/dev/null | awk '/^yay /{print $2; exit}') ;;
    ghostty)   version=$(ghostty --version 2>/dev/null | awk '{print $2; exit}') ;;
    fastfetch) version=$(fastfetch --version 2>/dev/null | awk '{print $2; exit}') ;;
    starship)  version=$(starship --version 2>/dev/null | awk '{print $2; exit}') ;;
    cursor)    version=$(cursor --version 2>/dev/null | awk '{print $1; exit}') ;;
    python|python3)
      version=$(python --version 2>/dev/null | awk '{print $2; exit}' || python3 --version 2>/dev/null | awk '{print $2; exit}')
      ;;
    go)        version=$(go version 2>/dev/null | awk '{print $3; exit}' | sed 's/go//') ;;
    terraform) version=$(terraform version 2>/dev/null | awk 'NR==1{print $2; exit}' | sed 's/^v//') ;;
    kubectl)   version=$(kubectl version --client=true 2>/dev/null | awk 'NR==1{print $3; exit}') ;;
    helm)      version=$(helm version --short 2>/dev/null | sed 's/^v//' | cut -d+ -f1) ;;
    ansible)
      version=$(ANSIBLE_LOCAL_TEMP=/tmp ansible --version 2>/dev/null | awk 'NR==1{print; exit}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
      ;;
    uv)        version=$(uv --version 2>/dev/null | awk '{print $2; exit}') ;;
    node)      version=$(node --version 2>/dev/null | sed 's/^v//') ;;
    gh)        version=$(gh --version 2>/dev/null | awk 'NR==1{print $3; exit}') ;;
    *)         version="ok" ;;
  esac
  if [[ -n "$version" ]]; then
    ok "$label  $version"
  else
    ok "$label"
  fi
}

check_unit() {
  local unit="$1"
  if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
    ok "$unit"
  else
    bad "$unit"
  fi
}

echo "──────── Recovery ────────"
if findmnt -no FSTYPE / | grep -qx btrfs; then
  ok "Btrfs  $(findmnt -no SOURCE /)"
else
  bad "Btrfs"
fi

if findmnt -no TARGET /.snapshots >/dev/null 2>&1; then
  ok "/.snapshots  $(findmnt -no SOURCE /.snapshots)"
else
  bad "/.snapshots"
fi

if [[ -f /etc/snapper/configs/root ]]; then
  count=$( { snapper -c root list 2>/dev/null || true; } | awk 'NR>2' | wc -l | tr -d '[:space:]')
  if [[ -z "$count" || "$count" == "0" ]]; then
    count=$(find /.snapshots -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]' || true)
  fi
  [[ -z "$count" ]] && count="?"
  ok "Snapper config  root ($count snapshots)"
else
  bad "Snapper config"
fi

[[ -f /etc/snapper/configs/home ]] && ok "Snapper config  home"

if pacman -Q grub-btrfs >/dev/null 2>&1; then
  ok "grub-btrfs  $(pacman -Q grub-btrfs | awk '{print $2}')"
else
  bad "grub-btrfs"
fi

check_unit snapper-timeline.timer
check_unit snapper-cleanup.timer
check_unit grub-btrfsd.service

echo
echo "──────── Backup (Borg) ────────"
ENV_FILE="${DOTFILES_BACKUP_ENV:-$HOME/.config/dotfiles/backup.env}"
if have_cmd borg; then
  ok "borg  $(borg --version 2>/dev/null | awk '{print $2; exit}')"
else
  bad "borg"
fi

if [[ -f "$ENV_FILE" ]]; then
  ok "backup.env  $ENV_FILE"
  # shellcheck disable=SC1090
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE" 2>/dev/null || true
  set +a
  if [[ -n "${BACKUP_REPO:-}" ]] && borg info "${BACKUP_REPO}" >/dev/null 2>&1; then
    archives=$(borg list "${BACKUP_REPO}" 2>/dev/null | wc -l | tr -d '[:space:]' || echo 0)
    ok "Borg repo  $BACKUP_REPO ($archives archives)"
  elif [[ -n "${BACKUP_REPO:-}" ]]; then
    warn "Borg repo  not initialized — run scripts/backup.sh init"
  else
    warn "Borg repo  BACKUP_REPO empty in env"
  fi
else
  warn "backup.env  missing (install/backup.sh)"
fi

if systemctl --user is-enabled --quiet dotfiles-backup.timer 2>/dev/null; then
  ok "dotfiles-backup.timer"
else
  warn "dotfiles-backup.timer  not enabled"
fi

if [[ -f /etc/pacman.d/hooks/99-dotfiles-backup.hook ]]; then
  ok "pacman backup hook"
else
  warn "pacman backup hook  missing"
fi

echo
echo "──────── Workstation ────────"
check_cmd yay yay

if have_cmd docker; then
  check_cmd Docker docker
  if systemctl is-active --quiet docker 2>/dev/null; then
    ok "Docker daemon  active"
  else
    bad "Docker daemon"
  fi
  target_user="${SUDO_USER:-$USER}"
  if id -nG "$target_user" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    ok "Docker group  $target_user"
  else
    warn "Docker group  $target_user not in docker (re-login after usermod)"
  fi
else
  bad "Docker"
fi

check_cmd Git git
check_cmd Ghostty ghostty
check_cmd Fastfetch fastfetch
check_cmd Starship starship
check_cmd Cursor cursor

if [[ "${SHELL:-}" == */zsh ]]; then
  ok "zsh default shell  $SHELL"
else
  warn "zsh default shell  current=$SHELL (chsh -s /usr/bin/zsh)"
fi

if [[ -d "$HOME/.ssh" ]] && compgen -G "$HOME/.ssh/*.pub" >/dev/null; then
  ok "Git SSH  keys present"
  if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/id_ed25519" ]] || [[ -f "$HOME/.ssh/id_rsa" ]]; then
    ok "Git SSH  identity files"
  fi
else
  bad "Git SSH"
fi

if have_cmd gpg && gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -q '^sec'; then
  ok "GPG  secret key present"
else
  warn "GPG  no secret key"
fi

if have_cmd gh; then
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub auth  logged in"
  else
    warn "GitHub auth  run: gh auth login"
  fi
else
  bad "GitHub auth  (install github-cli)"
fi

if [[ -f "$HOME/.config/Cursor/User/settings.json" ]] || \
   [[ -L "$HOME/.config/Cursor/User/settings.json" ]]; then
  ok "Cursor settings"
else
  warn "Cursor settings  missing (install/cursor.sh)"
fi

echo
echo "──────── DevOps ────────"
check_cmd kubectl kubectl
check_cmd Helm helm
check_cmd Terraform terraform
check_cmd Ansible ansible
check_cmd Go go
if have_cmd python || have_cmd python3; then
  check_cmd Python python
else
  bad "Python"
fi
check_cmd Node node
check_cmd uv uv

echo
echo "Setup:   $ROOT/install/snapper.sh"
echo "Backup:  $ROOT/scripts/backup.sh"
echo "Update:  $ROOT/scripts/update.sh"
echo "Boot:    $ROOT/bootstrap.sh"

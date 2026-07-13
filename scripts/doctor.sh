#!/usr/bin/env bash
# Workstation doctor: recovery stack + toolchain health in one place.

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
    docker)    version=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',') ;;
    git)       version=$(git --version | awk '{print $3}') ;;
    ghostty)   version=$(ghostty --version 2>/dev/null | head -1 | awk '{print $2}') ;;
    fastfetch) version=$(fastfetch --version 2>/dev/null | head -1 | awk '{print $2}') ;;
    starship)  version=$(starship --version 2>/dev/null | head -1 | awk '{print $2}') ;;
    cursor)    version=$(cursor --version 2>/dev/null | head -1 | awk '{print $1}') ;;
    python|python3)
      version=$(python --version 2>/dev/null | awk '{print $2}' || python3 --version 2>/dev/null | awk '{print $2}')
      ;;
    go)        version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//') ;;
    terraform) version=$(terraform version 2>/dev/null | head -1 | awk '{print $2}' | sed 's/^v//') ;;
    kubectl)   version=$(kubectl version --client=true 2>/dev/null | head -1 | awk '{print $3}') ;;
    helm)      version=$(helm version --short 2>/dev/null | sed 's/^v//' | cut -d+ -f1) ;;
    ansible)
      version=$(ANSIBLE_LOCAL_TEMP=/tmp ansible --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
      ;;
    uv)        version=$(uv --version 2>/dev/null | awk '{print $2}') ;;
    node)      version=$(node --version 2>/dev/null | sed 's/^v//') ;;
    gh)        version=$(gh --version 2>/dev/null | head -1 | awk '{print $3}') ;;
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

if [[ -f /etc/snapper/configs/root ]] || \
   (have_cmd snapper && snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | grep -qx root); then
  count=$( { snapper -c root list 2>/dev/null || true; } | awk 'NR>2' | wc -l | tr -d '[:space:]')
  if [[ -z "$count" || "$count" == "0" ]]; then
    count=$(find /.snapshots -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]' || true)
  fi
  [[ -z "$count" ]] && count="?"
  ok "Snapper root  ($count snapshots)"
else
  bad "Snapper"
fi

if [[ -f /etc/snapper/configs/home ]]; then
  ok "Snapper home"
fi

for pkg in snap-pac grub-btrfs btrfs-assistant; do
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    ok "$pkg  $(pacman -Q "$pkg" | awk '{print $2}')"
  else
    bad "$pkg"
  fi
done

check_unit snapper-timeline.timer
check_unit snapper-cleanup.timer
check_unit grub-btrfsd.service

echo
echo "──────── Workstation ────────"
check_cmd Docker docker
check_cmd Git git
check_cmd Ghostty ghostty
check_cmd Fastfetch fastfetch
check_cmd Starship starship
check_cmd Cursor cursor

if [[ -d "$HOME/.ssh" ]] && compgen -G "$HOME/.ssh/*.pub" >/dev/null; then
  ok "SSH  keys present"
else
  bad "SSH"
fi

if have_cmd gpg && gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -q '^sec'; then
  ok "GPG  secret key present"
else
  warn "GPG  no secret key"
fi

if have_cmd gh; then
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub  gh authenticated"
  else
    warn "GitHub  gh installed, not logged in (gh auth login)"
  fi
else
  bad "GitHub"
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
echo "Update:  $ROOT/scripts/update.sh"
echo "Boot:    $ROOT/bootstrap.sh"

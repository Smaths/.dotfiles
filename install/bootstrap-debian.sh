#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Dotfiles Bootstrap (Debian)
#
# Purpose:
# - Set up a Debian server bash shell using this dotfiles repo.
# - Keep reruns safe and idempotent, with backups before relinking.
#
# What this script does:
# 1) Validates Debian/bash runtime prerequisites
# 2) Optionally installs CLI packages from install/apt-packages.txt
# 3) Safely links ~/.bashrc to this repo
# 4) Verifies the resulting link
# 5) Optionally changes the login shell to bash with --force-shell
#
# Safety behavior:
# - Existing ~/.bashrc is backed up with a timestamp suffix before replacement.
# - --dry-run prints commands and planned changes without modifying the system.
# - Changing the login shell requires explicit --force-shell.
# -----------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
APT_MANIFEST="$DOTFILES_DIR/install/apt-packages.txt"
BASHRC_TARGET="$DOTFILES_DIR/config/bash/.bashrc"
BASHRC_LINK_PATH="$HOME/.bashrc"
TMUX_CONFIG_TARGET="$DOTFILES_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
DRY_RUN=0
SKIP_PACKAGES=0
FORCE_SHELL=0
VERBOSE=0
TOTAL_STEPS=6
CURRENT_STEP=0
OK_COUNT=0
SKIP_COUNT=0
START_TS="$(date +%s)"

usage() {
  cat <<'EOF'
Usage: bootstrap-debian.sh [options]

Options:
  --dry-run         Print actions without changing anything
  --verbose         Show more command details
  --skip-packages   Skip apt package installation
  --force-shell     Change the current user's login shell to bash
  -h, --help        Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --force-shell) FORCE_SHELL=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

step_start() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf '[%d/%d] %s\n' "$CURRENT_STEP" "$TOTAL_STEPS" "$1"
}

step_ok() {
  OK_COUNT=$((OK_COUNT + 1))
  printf '      OK: %s\n' "$1"
}

step_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  printf '      SKIP: %s\n' "$1"
}

run_cmd() {
  if ((DRY_RUN)); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run_as_root() {
  if ((EUID == 0)); then
    run_cmd "$@"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    run_cmd sudo "$@"
    return
  fi

  echo "ERROR: '$*' requires root. Re-run as root or install sudo." >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  local message="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Missing required command '$cmd'. $message" >&2
    exit 1
  fi
}

is_debian() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    [[ "${ID:-}" == "debian" || "${ID_LIKE:-}" == *debian* ]] && return 0
  fi

  [[ -r /etc/debian_version ]]
}

read_package_manifest() {
  local line
  PACKAGES=()
  MISSING_PACKAGES=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n "$line" ]] || continue
    PACKAGES+=("$line")
  done <"$APT_MANIFEST"
}

find_missing_packages() {
  local package
  MISSING_PACKAGES=()

  for package in "${PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
      if ((VERBOSE)); then
        echo "      package already installed: $package"
      fi
    else
      MISSING_PACKAGES+=("$package")
    fi
  done
}

link_with_backup() {
  local link_target="${1:-}"
  local link_path="${2:-}"

  if [[ -z "$link_target" || -z "$link_path" ]]; then
    echo "ERROR: link_with_backup requires target and link path" >&2
    return 1
  fi

  if [[ -L "$link_path" ]]; then
    local current_target
    current_target="$(readlink "$link_path")"
    if [[ "$current_target" == "$link_target" ]]; then
      if ((VERBOSE)); then
        echo "      link already correct: $link_path -> $link_target"
      fi
      return 0
    fi
  elif [[ -e "$link_path" ]]; then
    local backup="${link_path}.bak.$(date +%Y%m%d%H%M%S)"
    run_cmd mv "$link_path" "$backup"
    if ((VERBOSE)); then
      echo "      backed up: $link_path -> $backup"
    fi
  fi

  run_cmd ln -sfn "$link_target" "$link_path"
  if ((VERBOSE)); then
    echo "      linked: $link_path -> $link_target"
  fi
}

echo "snarfum dotfiles Debian bootstrap"
echo

step_start "Validate Debian runtime"
require_cmd uname "Install core system tools and retry."
require_cmd bash "Install bash and retry."
if ! is_debian; then
  echo "ERROR: This bootstrap is intended for Debian or Debian-like systems." >&2
  exit 1
fi
if [[ ! -f "$APT_MANIFEST" ]]; then
  echo "ERROR: Missing apt package manifest: $APT_MANIFEST" >&2
  exit 1
fi
if [[ ! -f "$BASHRC_TARGET" ]]; then
  echo "ERROR: Missing bashrc target: $BASHRC_TARGET" >&2
  exit 1
fi
step_ok "Debian-compatible system"

step_start "Install apt packages"
if ((SKIP_PACKAGES)); then
  step_skip "skipped (--skip-packages)"
else
  require_cmd apt-get "This bootstrap expects apt-get on Debian."
  require_cmd dpkg-query "This bootstrap expects dpkg-query on Debian."
  read_package_manifest
  if ((${#PACKAGES[@]} == 0)); then
    step_skip "manifest empty"
  else
    find_missing_packages
  fi

  if ((${#PACKAGES[@]} > 0 && ${#MISSING_PACKAGES[@]} == 0)); then
    step_skip "all packages already installed"
  elif ((${#MISSING_PACKAGES[@]} > 0)); then
    run_as_root apt-get update
    run_as_root apt-get install -y "${MISSING_PACKAGES[@]}"
    step_ok "${#MISSING_PACKAGES[@]} missing packages installed"
  fi
fi

step_start "Link bash config"
link_with_backup "$BASHRC_TARGET" "$BASHRC_LINK_PATH"
step_ok "linked/verified"

step_start "Verify bash config"
if ((DRY_RUN)); then
  step_skip "dry-run"
elif [[ "$(readlink "$BASHRC_LINK_PATH")" == "$BASHRC_TARGET" ]]; then
  bash -n "$BASHRC_TARGET"
  step_ok "$BASHRC_LINK_PATH -> $BASHRC_TARGET"
else
  echo "ERROR: Expected $BASHRC_LINK_PATH to link to $BASHRC_TARGET" >&2
  exit 1
fi

step_start "Link tmux config"
if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
  link_with_backup "$TMUX_CONFIG_TARGET" "$TMUX_CONFIG_LINK_PATH"
  step_ok "linked/verified"
else
  step_skip "target missing"
fi

step_start "Set login shell"
if ((FORCE_SHELL)); then
  bash_path="$(command -v bash)"
  current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  bash_path_real="$(readlink -f "$bash_path" 2>/dev/null || printf '%s\n' "$bash_path")"
  current_shell_real="$(readlink -f "$current_shell" 2>/dev/null || printf '%s\n' "$current_shell")"
  if [[ "$current_shell_real" == "$bash_path_real" ]]; then
    step_skip "already $bash_path"
  else
    run_cmd chsh -s "$bash_path" "$(id -un)"
    step_ok "$bash_path"
  fi
else
  step_skip "unchanged (pass --force-shell to change)"
fi

end_ts="$(date +%s)"
echo
echo "Done in $((end_ts - START_TS))s: ${OK_COUNT}/${TOTAL_STEPS} completed, ${SKIP_COUNT} skipped"
echo "Optional local overrides:"
echo "  cp ~/.dotfiles/config/bash/local.example.bash ~/.dotfiles/config/bash/local.bash"

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
# 2) Optionally installs CLI packages from install/platforms/debian/apt-packages.txt
# 3) Safely links ~/.bashrc to this repo
# 4) Verifies the resulting link
# 5) Safely links ~/.tmux.conf to this repo when available
# 6) Optionally changes the login shell to bash with --force-shell
#
# Safety behavior:
# - Existing ~/.bashrc and ~/.tmux.conf are backed up with timestamp suffixes
#   before replacement.
# - --dry-run prints commands and planned changes without modifying the system.
# - Changing the login shell requires explicit --force-shell.
# -----------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
APT_MANIFEST="$SCRIPT_DIR/apt-packages.txt"
BASHRC_TARGET="$DOTFILES_DIR/config/bash/.bashrc"
BASHRC_LINK_PATH="$HOME/.bashrc"
TMUX_CONFIG_TARGET="$DOTFILES_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
COMMON_LIB="$DOTFILES_DIR/install/lib/common.sh"
UI_LIB="$DOTFILES_DIR/install/lib/ui.sh"
DRY_RUN=0
YES=0
SKIP_PACKAGES=0
FORCE_SHELL=0
VERBOSE=0
TOTAL_STEPS=6

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [options]

Options:
  --dry-run         Print actions without changing anything
  --yes             Run without interactive confirmation
  --verbose         Show more command details
  --skip-packages   Skip apt package installation
  --force-shell     Change the current user's login shell to bash
  -h, --help        Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes) YES=1 ;;
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

if [[ ! -f "$COMMON_LIB" ]]; then
  printf 'ERROR: Missing shared bootstrap helper: %s\n' "$COMMON_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/common.sh
source "$COMMON_LIB"

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

print_preflight_plan() {
  printf '\n'
  printf 'Bootstrap plan (Debian)\n'
  printf '%s\n' '-----------------------'
  if ((SKIP_PACKAGES)); then
    printf '  apt packages: skipped (--skip-packages)\n'
  else
    printf '  apt packages: install missing entries only (%d listed)\n' "${#PACKAGES[@]}"
  fi
  printf '  bash link: %s -> %s\n' "$BASHRC_LINK_PATH" "$BASHRC_TARGET"
  if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
    printf '  tmux link: %s -> %s\n' "$TMUX_CONFIG_LINK_PATH" "$TMUX_CONFIG_TARGET"
  else
    printf '  tmux link: skipped (target missing)\n'
  fi
  if ((FORCE_SHELL)); then
    printf '  login shell: change current user to bash if needed\n'
  else
    printf '  login shell: unchanged (pass --force-shell to change)\n'
  fi
}

confirm_preflight() {
  local answer

  print_preflight_plan

  if ((DRY_RUN)); then
    printf '\nDry run: continuing without confirmation.\n'
    return 0
  fi

  if ((YES)); then
    printf '\nProceeding because --yes was passed.\n'
    return 0
  fi

  if [[ ! -t 0 ]]; then
    printf '\nERROR: Refusing to run mutating bootstrap without an interactive terminal.\n' >&2
    printf 'Pass --yes to run non-interactively or --dry-run to inspect planned actions.\n' >&2
    exit 1
  fi

  printf '\n'
  read -r -p "Proceed with these changes? [y/N]: " answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      printf 'Cancelled.\n'
      exit 0
      ;;
  esac
}

if [[ ! -f "$UI_LIB" ]]; then
  echo "ERROR: Missing shared UI helper: $UI_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/ui.sh
source "$UI_LIB"
ui_init "snarfum dotfiles Debian bootstrap" "$TOTAL_STEPS"
ui_print_header
ui_start

ui_step_start "Validate Debian runtime"
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
read_package_manifest
ui_step_ok "Debian-compatible system"

confirm_preflight

ui_step_start "Install apt packages"
if ((SKIP_PACKAGES)); then
  ui_step_skip "skipped (--skip-packages)"
else
  require_cmd apt-get "This bootstrap expects apt-get on Debian."
  require_cmd dpkg-query "This bootstrap expects dpkg-query on Debian."
  if ((${#PACKAGES[@]} == 0)); then
    ui_step_skip "manifest empty"
  else
    find_missing_packages
  fi

  if ((${#PACKAGES[@]} > 0 && ${#MISSING_PACKAGES[@]} == 0)); then
    ui_step_skip "all packages already installed"
  elif ((${#MISSING_PACKAGES[@]} > 0)); then
    echo "  missing packages: ${MISSING_PACKAGES[*]}"
    echo "  running: apt-get update"
    run_as_root apt-get update
    echo "  running: apt-get install -y ${MISSING_PACKAGES[*]}"
    run_as_root apt-get install -y "${MISSING_PACKAGES[@]}"
    ui_step_ok "${#MISSING_PACKAGES[@]} missing packages installed"
  fi
fi

ui_step_start "Link bash config"
link_with_backup "$BASHRC_TARGET" "$BASHRC_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

ui_step_start "Verify bash config"
if ((DRY_RUN)); then
  ui_step_skip "dry-run"
elif [[ "$(readlink "$BASHRC_LINK_PATH")" == "$BASHRC_TARGET" ]]; then
  bash -n "$BASHRC_TARGET"
  ui_step_ok "$BASHRC_LINK_PATH -> $BASHRC_TARGET"
else
  echo "ERROR: Expected $BASHRC_LINK_PATH to link to $BASHRC_TARGET" >&2
  exit 1
fi

ui_step_start "Link tmux config"
if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
  link_with_backup "$TMUX_CONFIG_TARGET" "$TMUX_CONFIG_LINK_PATH"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "linked/verified"
  fi
else
  ui_step_skip "target missing"
fi

ui_step_start "Set login shell"
if ((FORCE_SHELL)); then
  bash_path="$(command -v bash)"
  current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  bash_path_real="$(readlink -f "$bash_path" 2>/dev/null || printf '%s\n' "$bash_path")"
  current_shell_real="$(readlink -f "$current_shell" 2>/dev/null || printf '%s\n' "$current_shell")"
  if [[ "$current_shell_real" == "$bash_path_real" ]]; then
    ui_step_skip "already $bash_path"
  else
    run_cmd chsh -s "$bash_path" "$(id -un)"
    ui_step_ok "$bash_path"
  fi
else
  ui_step_skip "unchanged (pass --force-shell to change)"
fi

ui_summary
echo "Optional local overrides:"
echo "  cp ~/.dotfiles/config/bash/local.example.bash ~/.dotfiles/config/bash/local.bash"

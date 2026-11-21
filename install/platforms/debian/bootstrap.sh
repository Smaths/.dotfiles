#!/usr/bin/env bash
set -euo pipefail

# Install CLI packages and link Bash/tmux config on Debian and Ubuntu.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd)"
APT_MANIFEST="$SCRIPT_DIR/apt-packages.txt"
BASHRC_TARGET="$REPO_DIR/config/bash/.bashrc"
BASHRC_LINK_PATH="$HOME/.bashrc"
TMUX_CONFIG_TARGET="$REPO_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
COMMON_LIB="$REPO_DIR/install/lib/common.sh"
UI_LIB="$REPO_DIR/install/lib/ui.sh"
DRY_RUN=0
YES=0
SKIP_PACKAGES=0
FORCE_SHELL=0
VERBOSE=0
TOTAL_STEPS=5

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

  if ((DRY_RUN)) || command -v sudo >/dev/null 2>&1; then
    run_cmd sudo "$@"
    return
  fi

  echo "ERROR: Package installation requires sudo. Set up sudo for this user or pass --skip-packages." >&2
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
    if [[ "$(dpkg-query -W -f='${db:Status-Eflag} ${db:Status-Status}' "$package" 2>/dev/null)" == "ok installed" ]]; then
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
if ! is_debian; then
  echo "ERROR: This bootstrap is intended for Debian or Debian-like systems." >&2
  exit 1
fi
if ((! SKIP_PACKAGES)); then
  require_cmd apt-get "This bootstrap expects apt-get on Debian."
  require_cmd dpkg-query "This bootstrap expects dpkg-query on Debian."
  if [[ ! -f "$APT_MANIFEST" ]]; then
    echo "ERROR: Missing apt package manifest: $APT_MANIFEST" >&2
    exit 1
  fi
  read_package_manifest
fi
bash -n "$BASHRC_TARGET"
ui_step_ok "Debian-compatible system"

confirm_preflight

ui_step_start "Install apt packages"
if ((SKIP_PACKAGES)); then
  ui_step_skip "skipped (--skip-packages)"
else
  find_missing_packages
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    ui_step_skip "all packages already installed"
  else
    echo "  missing packages: ${MISSING_PACKAGES[*]}"
    run_as_root apt-get update --error-on=any
    install_cmd=(apt-get install -y --no-remove "${MISSING_PACKAGES[@]}")
    if ((YES)); then
      install_cmd=(env DEBIAN_FRONTEND=noninteractive "${install_cmd[@]}")
    fi
    run_as_root "${install_cmd[@]}"
    if ((DRY_RUN)); then
      ui_step_ok "planned"
    else
      ui_step_ok "${#MISSING_PACKAGES[@]} missing packages installed"
    fi
  fi
fi

ui_step_start "Link bash config"
link_with_backup "$BASHRC_TARGET" "$BASHRC_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "$BASHRC_LINK_PATH -> $BASHRC_TARGET"
fi

ui_step_start "Link tmux config"
if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
  link_with_backup "$TMUX_CONFIG_TARGET" "$TMUX_CONFIG_LINK_PATH"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "$TMUX_CONFIG_LINK_PATH -> $TMUX_CONFIG_TARGET"
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
printf '  cp %q %q\n' "$REPO_DIR/config/bash/local.example.bash" "$REPO_DIR/config/bash/local.bash"

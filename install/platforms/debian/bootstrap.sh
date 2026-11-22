#!/usr/bin/env bash
set -euo pipefail

# Use system Bash to bootstrap Zsh, tmux, and Pi on Debian and Ubuntu.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd)"
APT_MANIFEST="$SCRIPT_DIR/apt-packages.txt"
ZSH_CONFIG_DIR="$REPO_DIR/config/zsh"
# Zsh falls back to HOME only if ZDOTDIR is unset.
ZSH_STARTUP_DIR="${ZDOTDIR-$HOME}"
PROMPT_TARGET="$ZSH_CONFIG_DIR/prompts/purification/prompt_purification_setup"
TMUX_CONFIG_TARGET="$REPO_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
MISE_INSTALLER_URL="https://mise.run"
MISE_DEFAULT_BIN="$HOME/.local/bin/mise"
MISE_CONFIG_TARGET="$SCRIPT_DIR/mise.toml"
MISE_CONFIG_DIR_PATH="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
MISE_CONFIG_LINK_PATH="$MISE_CONFIG_DIR_PATH/conf.d/dotfiles-debian.toml"
COMMON_LIB="$REPO_DIR/install/lib/common.sh"
UI_LIB="$REPO_DIR/install/lib/ui.sh"
ZSH_PLUGINS_LIB="$REPO_DIR/install/lib/zsh-plugins.sh"
DRY_RUN=0
YES=0
SKIP_PACKAGES=0
SKIP_MISE=0
SKIP_PLUGINS=0
UPGRADE_PLUGINS=0
FORCE_SHELL=0
VERBOSE=0
TOTAL_STEPS=7

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [options]

Options:
  --dry-run          Print actions without changing anything
  --yes              Run without interactive confirmation
  --verbose          Show more command details
  --skip-packages    Skip apt, mise, and Pi installs (Zsh must already be installed)
  --skip-mise        Skip mise and Pi setup, but still install apt packages
  --skip-plugins     Skip plugin sync (no Git or network access needed for this step)
  --upgrade-plugins  Fast-forward Zsh plugins to their upstream default branches
  --force-shell      Change the current user's login shell to Zsh
  -h, --help         Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes) YES=1 ;;
    --verbose) VERBOSE=1 ;;
    --skip-packages)
      SKIP_PACKAGES=1
      SKIP_MISE=1
      ;;
    --skip-mise) SKIP_MISE=1 ;;
    --skip-plugins) SKIP_PLUGINS=1 ;;
    --upgrade-plugins) UPGRADE_PLUGINS=1 ;;
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

if ((SKIP_PLUGINS && UPGRADE_PLUGINS)); then
  printf 'ERROR: --skip-plugins and --upgrade-plugins cannot be combined.\n' >&2
  exit 1
fi

if [[ ! -f "$COMMON_LIB" ]]; then
  printf 'ERROR: Missing shared bootstrap helper: %s\n' "$COMMON_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/common.sh
source "$COMMON_LIB"

if ((! SKIP_PLUGINS)); then
  if [[ ! -f "$ZSH_PLUGINS_LIB" ]]; then
    printf 'ERROR: Missing Zsh plugin helper: %s\n' "$ZSH_PLUGINS_LIB" >&2
    exit 1
  fi
  # shellcheck source=install/lib/zsh-plugins.sh
  source "$ZSH_PLUGINS_LIB"
  ZSH_PLUGIN_ROOT="$(zsh_plugin_root)"
fi

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

install_mise() (
  local destination="$1" installer
  require_cmd curl "Install curl to download mise, or pass --skip-mise."
  installer="$(mktemp)"
  trap 'rm -f -- "$installer"' EXIT
  curl --fail --silent --show-error --location --retry 3 --proto '=https' \
    --output "$installer" "$MISE_INSTALLER_URL"
  MISE_INSTALL_PATH="$destination" sh "$installer"
  [[ -x "$destination" ]]
)

print_preflight_plan() {
  printf '\n'
  printf 'Bootstrap plan (Debian)\n'
  printf '%s\n' '-----------------------'
  if ((SKIP_PACKAGES)); then
    printf '  apt packages: skipped (--skip-packages)\n'
  else
    printf '  apt packages: install missing entries only (%d listed)\n' "${#PACKAGES[@]}"
  fi
  if ((SKIP_MISE)); then
    printf '  mise and Pi: skipped\n'
  else
    if [[ -n "$mise_bin" ]]; then
      printf '  mise: reuse %s\n' "$mise_bin"
    else
      printf '  mise: install from %s to %s\n' "$MISE_INSTALLER_URL" "$MISE_DEFAULT_BIN"
    fi
    printf '  Pi: link %s and install the configured version\n' "$MISE_CONFIG_LINK_PATH"
  fi
  printf '  Zsh links: %s and %s -> %s\n' "$ZSH_STARTUP_DIR/.zshrc" "$ZSH_STARTUP_DIR/.zprofile" "$ZSH_CONFIG_DIR"
  if ((SKIP_PLUGINS)); then
    printf '  Zsh plugins: skipped (--skip-plugins)\n'
  else
    printf '  Zsh plugins: install missing plugins in %s\n' "$ZSH_PLUGIN_ROOT"
    if ((UPGRADE_PLUGINS)); then
      printf '               fast-forward existing clones to upstream HEAD\n'
    fi
  fi
  if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
    printf '  tmux link: %s -> %s\n' "$TMUX_CONFIG_LINK_PATH" "$TMUX_CONFIG_TARGET"
  else
    printf '  tmux link: skipped (target missing)\n'
  fi
  if ((FORCE_SHELL)); then
    printf '  login shell: change current user to Zsh if needed\n'
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
if ((! SKIP_MISE)); then
  if [[ ! -f "$MISE_CONFIG_TARGET" ]]; then
    printf 'ERROR: Missing mise config: %s\n' "$MISE_CONFIG_TARGET" >&2
    exit 1
  fi
  if [[ -n "${MISE_GLOBAL_CONFIG_FILE:-}" || "$MISE_CONFIG_DIR_PATH" != /* ]]; then
    printf 'ERROR: Pi setup requires an absolute mise config directory with no MISE_GLOBAL_CONFIG_FILE override. Correct the environment or pass --skip-mise.\n' >&2
    exit 1
  fi
  mise_bin="$(type -P mise || true)"
  # Bash may not have the standalone install on PATH yet.
  if [[ -z "$mise_bin" && -f "$MISE_DEFAULT_BIN" && -x "$MISE_DEFAULT_BIN" ]]; then
    mise_bin="$MISE_DEFAULT_BIN"
  elif [[ -z "$mise_bin" && (-e "$MISE_DEFAULT_BIN" || -L "$MISE_DEFAULT_BIN") ]]; then
    printf 'ERROR: Cannot install mise over %s. Move it aside or pass --skip-mise.\n' "$MISE_DEFAULT_BIN" >&2
    exit 1
  fi
fi
if [[ "$ZSH_STARTUP_DIR" != /* ]]; then
  printf 'ERROR: The Zsh startup directory (ZDOTDIR or HOME) must be absolute: %s\n' "$ZSH_STARTUP_DIR" >&2
  exit 1
fi
if [[ -e "$ZSH_STARTUP_DIR" && ! -d "$ZSH_STARTUP_DIR" ]]; then
  printf 'ERROR: The Zsh startup path is not a directory: %s\n' "$ZSH_STARTUP_DIR" >&2
  exit 1
fi
zsh_startup_files=(
  "$ZSH_CONFIG_DIR"/{.zshrc,.zprofile,path.zsh,options.zsh,env.zsh,completion.zsh,plugins.zsh,aliases.zsh}
  "$PROMPT_TARGET"
)
for startup_file in "${zsh_startup_files[@]}"; do
  if [[ ! -f "$startup_file" ]]; then
    printf 'ERROR: Missing Zsh startup file: %s\n' "$startup_file" >&2
    exit 1
  fi
done
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

# A clean system need not have Zsh or Git to preview bootstrap.
if ((! DRY_RUN)); then
  require_cmd zsh "Install Zsh with apt or rerun without --skip-packages."
fi
if command -v zsh >/dev/null 2>&1; then
  for startup_file in "${zsh_startup_files[@]}"; do
    zsh -fn "$startup_file"
  done
fi

ui_step_start "Install mise and Pi"
if ((SKIP_MISE)); then
  ui_step_skip "skipped"
else
  if [[ -z "$mise_bin" ]]; then
    mise_bin="$MISE_DEFAULT_BIN"
    if ((! DRY_RUN)); then
      install_mise "$mise_bin"
    fi
  fi
  run_cmd mkdir -p -- "$MISE_CONFIG_DIR_PATH/conf.d"
  link_with_backup "$MISE_CONFIG_TARGET" "$MISE_CONFIG_LINK_PATH"
  # Only install Pi, and ignore the configuration of the calling project.
  run_cmd env MISE_PARANOID=1 "$mise_bin" --cd / install --yes pi
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "Pi ready via mise"
  fi
fi

ui_step_start "Install Zsh plugins"
if ((SKIP_PLUGINS)); then
  ui_step_skip "skipped (--skip-plugins)"
else
  if ((! DRY_RUN)); then
    require_cmd git "Install Git to sync Zsh plugins, or pass --skip-plugins."
  fi
  sync_zsh_plugins "$ZSH_PLUGIN_ROOT" "$UPGRADE_PLUGINS"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "$ZSH_PLUGINS_CLONED cloned, $ZSH_PLUGINS_UPDATED updated, $ZSH_PLUGINS_UNCHANGED unchanged, $ZSH_PLUGINS_UNMANAGED unmanaged"
  fi
fi

ui_step_start "Link Zsh config"
if [[ ! -d "$ZSH_STARTUP_DIR" ]]; then
  run_cmd mkdir -p -- "$ZSH_STARTUP_DIR"
fi
link_with_backup "$ZSH_CONFIG_DIR/.zshrc" "$ZSH_STARTUP_DIR/.zshrc"
link_with_backup "$ZSH_CONFIG_DIR/.zprofile" "$ZSH_STARTUP_DIR/.zprofile"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked .zshrc and .zprofile"
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
  # Use a registered distro shell, not a user binary or shim on PATH.
  zsh_path=""
  for candidate in /usr/bin/zsh /bin/zsh; do
    if [[ -x "$candidate" ]] && grep -Fxq "$candidate" /etc/shells; then
      zsh_path="$candidate"
      break
    fi
  done
  if [[ -z "$zsh_path" ]]; then
    if ((! DRY_RUN)); then
      printf 'ERROR: No apt-installed Zsh login shell registered in /etc/shells.\n' >&2
      exit 1
    fi
    zsh_path=/usr/bin/zsh
  fi
  user="$(id -un)"
  passwd_entry="$(getent passwd "$user")"
  current_shell="${passwd_entry##*:}"
  if [[ -n "$current_shell" && "$(readlink -f "$current_shell")" == "$(readlink -f "$zsh_path")" ]]; then
    ui_step_skip "already $current_shell"
  else
    run_cmd chsh -s "$zsh_path" "$user"
    ui_step_ok "$zsh_path"
  fi
else
  ui_step_skip "unchanged (pass --force-shell to change)"
fi

ui_summary
echo "Start a Zsh login session with: exec zsh -l"
echo "Optional local overrides:"
printf '  cp -n %q %q\n' "$ZSH_CONFIG_DIR/local.example.zsh" "$ZSH_CONFIG_DIR/local.zsh"

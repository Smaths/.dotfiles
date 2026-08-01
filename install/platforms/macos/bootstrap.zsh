#!/usr/bin/env zsh
set -euo pipefail

# -----------------------------------------------------------------------------
# Dotfiles Bootstrap (macOS)
#
# Purpose:
# - Set up a fresh or existing macOS machine using this dotfiles repo.
# - Keep reruns safe (idempotent where possible, with backups before relinking).
#
# What this script does:
# 1) Validates runtime prerequisites and platform
# 2) Installs Homebrew if missing
# 3) Installs packages/apps from Brewfile
# 4) Links config/mise/config.toml to the XDG path mise reads by default
# 5) Installs pinned Node.js and pnpm versions with mise
# 6) Installs git via Homebrew when missing
# 7) Safely links ~/.zshrc and ~/.zprofile to this repo
#
# Safety behavior:
# - Existing ~/.zshrc and ~/.zprofile are backed up with timestamp suffixes
#   before symlinks are replaced.
# - --dry-run prints commands and planned changes without modifying the system.
# -----------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SCRIPT_DIR="${0:A:h}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BREWFILE="$SCRIPT_DIR/Brewfile"
MISE_CONFIG_TARGET="$DOTFILES_DIR/config/mise/config.toml"
MISE_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/mise/config.toml"
ZSHRC_TARGET="$DOTFILES_DIR/config/zsh/.zshrc"
ZPROFILE_TARGET="$DOTFILES_DIR/config/zsh/.zprofile"
GHOSTTY_CONFIG_TARGET="$DOTFILES_DIR/config/ghostty/config"
GHOSTTY_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/ghostty/config"
TMUX_CONFIG_TARGET="$DOTFILES_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
COMMON_LIB="$DOTFILES_DIR/install/lib/common.sh"
UI_LIB="$DOTFILES_DIR/install/lib/ui.sh"
DRY_RUN=0
YES=0
INSTALL_GIT=0
UPGRADE_PACKAGES=0
VERBOSE=0
BREW_BIN=""
BREWFILE_PACKAGE_COUNT=0
TOTAL_STEPS=8

usage() {
  cat <<'EOF'
Usage: bootstrap.zsh [options]

Options:
  --dry-run            Print actions without changing anything
  --yes                Run without interactive confirmation
  --verbose            Show more command details
  --upgrade-packages   Upgrade outdated Brewfile packages during bootstrap
  -h, --help           Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes) YES=1 ;;
    --verbose) VERBOSE=1 ;;
    --upgrade-packages) UPGRADE_PACKAGES=1 ;;
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

on_error() {
  local exit_code="$1"
  local line_no="$2"
  local command="${3:-unknown command}"

  # Ctrl+C / signal-driven exits can still trigger ERR in zsh.
  # Keep interrupt output clean and avoid a misleading failure line.
  if ((exit_code == 130 || exit_code == 143 || exit_code == -3)); then
    return 0
  fi

  echo
  echo "ERROR: bootstrap failed at line $line_no: $command (exit $exit_code)" >&2
}

resolve_brew_bin() {
  # Determine brew executable even when PATH is not initialized yet.
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo "/opt/homebrew/bin/brew"
    return 0
  fi
  if [[ -x /usr/local/bin/brew ]]; then
    echo "/usr/local/bin/brew"
    return 0
  fi
  return 1
}

count_brewfile_packages() {
  # Count active Brewfile dependency declarations for progress output.
  awk '
    /^[[:space:]]*(brew|cask|tap|mas|vscode|go|cargo|uv|npm)[[:space:]]/ { count++ }
    END { print count + 0 }
  ' "$BREWFILE"
}

print_preflight_plan() {
  echo
  echo "Bootstrap plan (macOS)"
  echo "----------------------"
  if [[ -n "$BREW_BIN" ]]; then
    echo "  Homebrew: already installed at $BREW_BIN"
  else
    echo "  Homebrew: install using the official installer"
  fi
  if ((UPGRADE_PACKAGES)); then
    echo "  Brewfile packages: install missing entries and upgrade outdated entries"
  else
    echo "  Brewfile packages: install missing entries only"
  fi
  echo "  mise config link: $MISE_CONFIG_LINK_PATH"
  echo "  mise runtimes: install pinned Node.js and pnpm versions"
  echo "  Git: install with Homebrew only if missing"
  echo "  Shell links: ~/.zshrc and ~/.zprofile"
  if [[ -f "$GHOSTTY_CONFIG_TARGET" ]]; then
    echo "  Ghostty link: $GHOSTTY_CONFIG_LINK_PATH"
  else
    echo "  Ghostty link: skipped (target missing)"
  fi
  if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
    echo "  tmux link: $TMUX_CONFIG_LINK_PATH"
  else
    echo "  tmux link: skipped (target missing)"
  fi
}

confirm_preflight() {
  local answer

  print_preflight_plan

  if ((DRY_RUN)); then
    echo
    echo "Dry run: continuing without confirmation."
    return 0
  fi

  if ((YES)); then
    echo
    echo "Proceeding because --yes was passed."
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo
    echo "ERROR: Refusing to run mutating bootstrap without an interactive terminal." >&2
    echo "Pass --yes to run non-interactively or --dry-run to inspect planned actions." >&2
    exit 1
  fi

  echo
  read -r "?Proceed with these changes? [y/N]: " answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      echo "Cancelled."
      exit 0
      ;;
  esac
}

show_brewfile_misses() {
  echo "  Brewfile is not satisfied. Details:"
  if ((UPGRADE_PACKAGES)); then
    brew bundle check --verbose --file="$BREWFILE" || true
  else
    env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file="$BREWFILE" || true
  fi
}

if [[ ! -f "$UI_LIB" ]]; then
  echo "ERROR: Missing shared UI helper: $UI_LIB" >&2
  exit 1
fi
# shellcheck source=../lib/ui.sh
source "$UI_LIB"
ui_init "snarfum dotfiles bootstrap" "$TOTAL_STEPS"
ui_print_header
ui_start
trap 'on_error $? $LINENO "${ZSH_COMMAND:-}"' ERR

# This bootstrap is intentionally macOS-only.
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: This bootstrap is intended for macOS (Darwin). Detected: $(uname -s)" >&2
  exit 1
fi

# Preflight requirements before network/package steps.
require_cmd uname "Install core system tools and retry."
require_cmd curl "curl is expected to be present on macOS. If it's missing, your PATH/environment is broken or the OS install is atypical. Fix PATH or reinstall base system tools and retry."

# Validate required project files before applying changes.
if [[ ! -f "$BREWFILE" ]]; then
  echo "ERROR: Brewfile not found at $BREWFILE"
  exit 1
fi

if [[ ! -f "$ZSHRC_TARGET" ]]; then
  echo "ERROR: Missing symlink target: $ZSHRC_TARGET" >&2
  exit 1
fi

if [[ ! -f "$ZPROFILE_TARGET" ]]; then
  echo "ERROR: Missing symlink target: $ZPROFILE_TARGET" >&2
  exit 1
fi

if [[ ! -f "$MISE_CONFIG_TARGET" ]]; then
  echo "ERROR: Missing mise config: $MISE_CONFIG_TARGET" >&2
  exit 1
fi

ui_step_start "Resolve Homebrew"
if BREW_BIN="$(resolve_brew_bin)"; then
  ui_step_ok "$BREW_BIN"
else
  ui_step_skip "not installed"
fi

confirm_preflight

# Install Homebrew if absent.
ui_step_start "Install Homebrew"
if [[ -z "$BREW_BIN" ]]; then
  if ((DRY_RUN)); then
    echo "[dry-run] /bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'"
  else
    echo "  running Homebrew installer in the foreground"
    /bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
  fi
  if ! BREW_BIN="$(resolve_brew_bin)"; then
    if ((DRY_RUN)); then
      BREW_BIN="<homebrew path after install>"
    else
      echo "ERROR: Homebrew installer completed but brew could not be resolved." >&2
      exit 1
    fi
  fi
  ui_step_ok "$BREW_BIN"
else
  ui_step_skip "already installed"
fi

# Load brew into this shell so subsequent brew commands work immediately.
if [[ -n "$BREW_BIN" && "$BREW_BIN" != "<homebrew path after install>" ]]; then
  eval "$("$BREW_BIN" shellenv)"
fi

# If git is missing, install it after brew is available.
if ! command -v git >/dev/null 2>&1; then
  INSTALL_GIT=1
  if ((VERBOSE)); then
    echo "  git missing; will install"
  fi
fi

BREWFILE_PACKAGE_COUNT="$(count_brewfile_packages)"
ui_step_start "Install Brewfile packages (${BREWFILE_PACKAGE_COUNT})"
if ((DRY_RUN)) && [[ "$BREW_BIN" == "<homebrew path after install>" ]]; then
  if ((UPGRADE_PACKAGES)); then
    echo "[dry-run] brew bundle install --file=\"$BREWFILE\" --jobs=auto"
  else
    echo "[dry-run] brew bundle install --file=\"$BREWFILE\" --no-upgrade --jobs=auto"
  fi
  ui_step_ok "planned after Homebrew install"
else
  BREWFILE_READY=0
  if ((UPGRADE_PACKAGES)); then
    if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
      BREWFILE_READY=1
    fi
  else
    if env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$BREWFILE" >/dev/null 2>&1; then
      BREWFILE_READY=1
    fi
  fi

  if ((BREWFILE_READY && !INSTALL_GIT)); then
    if ((UPGRADE_PACKAGES)); then
      ui_step_skip "already installed/up to date"
    else
      ui_step_skip "already installed"
    fi
  else
    if ((!BREWFILE_READY)); then
      show_brewfile_misses
      if ((UPGRADE_PACKAGES)); then
        run_cmd brew bundle install --file="$BREWFILE" --jobs=auto
      else
        run_cmd brew bundle install --file="$BREWFILE" --no-upgrade --jobs=auto
      fi
    fi

    # Install git only when missing to keep reruns minimal.
    if ((INSTALL_GIT)); then
      run_cmd brew install git
    fi

    if ((DRY_RUN)); then
      ui_step_ok "planned"
    else
      ui_step_ok "brew bundle complete"
    fi
  fi
fi

# Link the tracked mise config to the path mise reads by default, so every
# process resolves the same toolchain -- not just shells that source .zshrc.
ui_step_start "Link mise config"
run_cmd mkdir -p "${MISE_CONFIG_LINK_PATH:h}"
link_with_backup "$MISE_CONFIG_TARGET" "$MISE_CONFIG_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

ui_step_start "Install mise runtimes"
if ((!DRY_RUN)) && ! command -v mise >/dev/null 2>&1; then
  echo "ERROR: mise was not installed by Brew Bundle." >&2
  exit 1
fi
run_cmd mise install --yes
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "Node.js and pnpm installed/verified"
fi

ui_step_start "Link shell config files"
link_with_backup "$ZSHRC_TARGET" "$HOME/.zshrc"
link_with_backup "$ZPROFILE_TARGET" "$HOME/.zprofile"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

# Link Ghostty config to XDG default path when present.
ui_step_start "Link Ghostty config"
if [[ -f "$GHOSTTY_CONFIG_TARGET" ]]; then
  run_cmd mkdir -p "$XDG_CONFIG_HOME/ghostty"
  link_with_backup "$GHOSTTY_CONFIG_TARGET" "$GHOSTTY_CONFIG_LINK_PATH"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "linked/verified"
  fi
else
  ui_step_skip "target missing"
fi

# Link tmux config to ~/.tmux.conf when present.
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

ui_summary
echo "Optional local overrides:"
echo "  cp ~/.dotfiles/config/zsh/local.example.zsh ~/.dotfiles/config/zsh/local.zsh"
echo "  Example: add aliases, PATH entries, or machine-specific env vars to local.zsh"
echo "           alias work='cd ~/code/work'"

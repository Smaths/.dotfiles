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
# 3) Installs packages/apps from brew/Brewfile
# 4) Installs git via Homebrew when missing
# 5) Safely links ~/.zshrc and ~/.zprofile to this repo
# 6) Optionally runs install/macos.zsh for interactive macOS settings
#
# Safety behavior:
# - Existing ~/.zshrc and ~/.zprofile are backed up with timestamp suffixes
#   before symlinks are replaced.
# - --dry-run prints commands and planned changes without modifying the system.
# -----------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BREWFILE="$DOTFILES_DIR/brew/Brewfile"
ZSHRC_TARGET="$DOTFILES_DIR/config/zsh/.zshrc"
ZPROFILE_TARGET="$DOTFILES_DIR/config/zsh/.zprofile"
DRY_RUN=0
SKIP_MACOS=0
INSTALL_GIT=0
BREW_BIN=""

usage() {
  cat <<'EOF'
Usage: bootstrap.zsh [options]

Options:
  --dry-run         Print actions without changing anything
  --skip-macos      Skip install/macos.zsh execution
  --skip-macros     Alias of --skip-macos
  -h, --help        Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --skip-macos|--skip-macros) SKIP_MACOS=1 ;;
    -h|--help)
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

run_cmd() {
  # Helper to centralize dry-run behavior for command execution.
  if (( DRY_RUN )); then
    echo "[dry-run] $*"
  else
    "$@"
  fi
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

require_cmd() {
  # Hard fail with a contextual message when a required command is missing.
  local cmd="$1"
  local msg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Missing required command '$cmd'. $msg" >&2
    exit 1
  fi
}

echo "==> Dotfiles bootstrap starting"

# This bootstrap is intentionally macOS-only.
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: This bootstrap is intended for macOS (Darwin). Detected: $(uname -s)" >&2
  exit 1
fi

# Preflight requirements before network/package steps.
require_cmd uname "Install core system tools and retry."
require_cmd curl "Install curl (for example via Xcode Command Line Tools) and retry."

# Install Homebrew if absent.
if ! BREW_BIN="$(resolve_brew_bin)"; then
  echo "==> Homebrew not found. Installing Homebrew..."
  if (( DRY_RUN )); then
    echo "[dry-run] /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  BREW_BIN="$(resolve_brew_bin)"
fi

echo "==> Using brew at: $BREW_BIN"

# Load brew into this shell so subsequent brew commands work immediately.
if [[ -n "$BREW_BIN" ]]; then
  eval "$("$BREW_BIN" shellenv)"
fi

# If git is missing, install it after brew is available.
if ! command -v git >/dev/null 2>&1; then
  INSTALL_GIT=1
  echo "==> git not found. It will be installed with Homebrew."
fi

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

echo "==> Installing from Brewfile"
run_cmd brew bundle --file="$BREWFILE"

# Install git only when missing to keep reruns minimal.
if (( INSTALL_GIT )); then
  echo "==> Installing git"
  run_cmd brew install git
fi

# Symlink helper:
# - If the link already points to the right target, do nothing.
# - If a file exists, move it to a timestamped backup before linking.
link_with_backup() {
  local target="$1"
  local link_path="$2"

  if [[ -L "$link_path" ]]; then
    local current_target
    current_target="$(readlink "$link_path")"
    if [[ "$current_target" == "$target" ]]; then
      echo "==> Symlink already correct: $link_path -> $target"
      return
    fi
  elif [[ -e "$link_path" ]]; then
    local backup="${link_path}.bak.$(date +%Y%m%d%H%M%S)"
    if (( DRY_RUN )); then
      echo "==> Would back up existing file: $link_path -> $backup"
    else
      run_cmd mv "$link_path" "$backup"
      echo "==> Backed up existing file: $link_path -> $backup"
    fi
  fi

  if (( DRY_RUN )); then
    echo "==> Would link: $link_path -> $target"
    run_cmd ln -sfn "$target" "$link_path"
  else
    run_cmd ln -sfn "$target" "$link_path"
    echo "==> Linked: $link_path -> $target"
  fi
}

echo "==> Creating shell config symlinks"
link_with_backup "$ZSHRC_TARGET" "$HOME/.zshrc"
link_with_backup "$ZPROFILE_TARGET" "$HOME/.zprofile"

# Run interactive macOS settings unless explicitly skipped.
MACOS_SCRIPT="$DOTFILES_DIR/install/macos.zsh"
if (( SKIP_MACOS )); then
  echo "==> Skipping macOS setup (--skip-macos)"
elif [[ -f "$MACOS_SCRIPT" ]]; then
  echo "==> Running macOS setup script"
  run_cmd zsh "$MACOS_SCRIPT"
else
  echo "==> Skipping macOS setup (script not found: $MACOS_SCRIPT)"
fi

echo "==> Bootstrap complete"
echo "Optional local overrides:"
echo "  cp \"$DOTFILES_DIR/config/zsh/local.example.zsh\" \"$DOTFILES_DIR/config/zsh/local.zsh\""

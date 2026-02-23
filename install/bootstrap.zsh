#!/usr/bin/env zsh
set -euo pipefail

# Bootstraps a fresh/existing macOS machine with:
# 1) Homebrew installation (if missing)
# 2) Brewfile package installation
# 3) Safe symlink setup for ~/.zshrc and ~/.zprofile
# 4) Optional interactive macOS defaults script

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BREWFILE="$DOTFILES_DIR/brew/Brewfile"
ZSHRC_TARGET="$DOTFILES_DIR/config/zsh/.zshrc"
ZPROFILE_TARGET="$DOTFILES_DIR/config/zsh/.zprofile"

echo "==> Dotfiles bootstrap starting"

if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Load brew into the current shell for this script run.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ ! -f "$BREWFILE" ]]; then
  echo "ERROR: Brewfile not found at $BREWFILE"
  exit 1
fi

echo "==> Installing from Brewfile"
brew bundle --file="$BREWFILE"

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
    mv "$link_path" "$backup"
    echo "==> Backed up existing file: $link_path -> $backup"
  fi

  ln -sfn "$target" "$link_path"
  echo "==> Linked: $link_path -> $target"
}

echo "==> Creating shell config symlinks"
link_with_backup "$ZSHRC_TARGET" "$HOME/.zshrc"
link_with_backup "$ZPROFILE_TARGET" "$HOME/.zprofile"

# Run interactive macOS settings if the script exists.
MACOS_SCRIPT="$DOTFILES_DIR/install/macos.zsh"
if [[ -f "$MACOS_SCRIPT" ]]; then
  echo "==> Running macOS setup script"
  zsh "$MACOS_SCRIPT"
else
  echo "==> Skipping macOS setup (script not found: $MACOS_SCRIPT)"
fi

echo "==> Bootstrap complete"
echo "Optional local overrides:"
echo "  cp \"$DOTFILES_DIR/config/zsh/local.example.zsh\" \"$DOTFILES_DIR/config/zsh/local.zsh\""

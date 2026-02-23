# Main zsh entrypoint for this dotfiles repo.
# This file should be symlinked to ~/.zshrc by install/bootstrap.zsh.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
ZSH_CONFIG_DIR="$DOTFILES_DIR/config/zsh"
ZSH_PROFILE_STARTUP="${ZSH_PROFILE_STARTUP:-0}"

if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
  zmodload zsh/zprof
fi

# Core shell behavior first.
source "$ZSH_CONFIG_DIR/options.zsh"
source "$ZSH_CONFIG_DIR/path.zsh"
source "$ZSH_CONFIG_DIR/env.zsh"

# Completions and plugins next.
source "$ZSH_CONFIG_DIR/completion.zsh"
source "$ZSH_CONFIG_DIR/plugins.zsh"

# Functions and aliases last.
for f in "$ZSH_CONFIG_DIR"/functions/*.zsh(N); do
  [[ -r "$f" ]] && source "$f"
done
source "$ZSH_CONFIG_DIR/aliases.zsh"

# Local machine overrides are opt-in and gitignored by convention.
[[ -r "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"

if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
  zprof
fi

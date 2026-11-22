# Main zsh entrypoint for this dotfiles repo.
# Linked to ~/.zshrc by install/bootstrap.sh.

# Resolve the checkout from this file, even through the home-directory symlink.
DOTFILES_DIR="${DOTFILES_DIR:-${${(%):-%x}:A:h:h:h}}"
ZSH_CONFIG_DIR="$DOTFILES_DIR/config/zsh"
# Git-cloned plugins live outside the repo, under XDG data. Bootstrap resolves
# the same path in install/lib/zsh-plugins.sh; keep the two in sync. Ignore
# relative XDG paths so plugins are never sourced from the working directory.
if [[ "${XDG_DATA_HOME:-}" == /* ]]; then
  ZSH_PLUGIN_DIR="$XDG_DATA_HOME/zsh/plugins"
else
  ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
fi
ZSH_PROFILE_STARTUP="${ZSH_PROFILE_STARTUP:-0}"

if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
  zmodload zsh/zprof
fi

# Core shell behavior first.
source "$ZSH_CONFIG_DIR/options.zsh"
source "$ZSH_CONFIG_DIR/env.zsh"

# Completions and plugins next.
source "$ZSH_CONFIG_DIR/completion.zsh"
source "$ZSH_CONFIG_DIR/plugins.zsh"

# Functions and aliases last.
for f in "$ZSH_CONFIG_DIR"/functions/*.zsh(N); do
  [[ -r "$f" ]] && source "$f"
done
source "$ZSH_CONFIG_DIR/aliases.zsh"

# Local machine overrides stay gitignored; source snippets in stable name order.
[[ -r "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"
for f in "$ZSH_CONFIG_DIR"/local.d/*.zsh(N); do
  [[ -r "$f" ]] && source "$f"
done

if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
  zprof
fi

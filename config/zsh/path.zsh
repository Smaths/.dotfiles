# PATH management (macOS / Homebrew friendly)
typeset -U path PATH

# Keep user bins first.
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/Library/Python/3.9/bin"
  $path
)

# MCP server binaries.
[[ -d "$HOME/.config/mcp/bin" ]] && path=("$HOME/.config/mcp/bin" $path)

# Homebrew prefixes (Apple Silicon + Intel fallback).
[[ -d /usr/local/bin ]] && path=(/usr/local/bin /usr/local/sbin $path)
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

# Herd tools.
[[ -d "$HOME/Library/Application Support/Herd/bin" ]] && path=("$HOME/Library/Application Support/Herd/bin" $path)

# Keg-only MySQL LTS.
[[ -d /usr/local/opt/mysql@8.4/bin ]] && path=(/usr/local/opt/mysql@8.4/bin $path)
[[ -d /opt/homebrew/opt/mysql@8.4/bin ]] && path=(/opt/homebrew/opt/mysql@8.4/bin $path)

# mise-managed runtimes. Shims are the single activation mechanism: they work in
# login, non-interactive, and non-zsh contexts, and still resolve per-project
# versions from .nvmrc, .node-version, and packageManager. Do not also add
# `mise activate` -- running both mechanisms is unsupported.
MISE_SHIMS_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
[[ -d "$MISE_SHIMS_DIR" ]] && path=("$MISE_SHIMS_DIR" $path)
unset MISE_SHIMS_DIR

export PATH

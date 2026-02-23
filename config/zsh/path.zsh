# PATH management (macOS / Homebrew friendly)
typeset -U path PATH

# Keep user bins first.
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)

# Homebrew prefixes (Apple Silicon + Intel fallback).
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
[[ -d /usr/local/bin ]] && path=(/usr/local/bin /usr/local/sbin $path)

# Herd tools.
[[ -d "$HOME/Library/Application Support/Herd/bin" ]] && path=("$HOME/Library/Application Support/Herd/bin" $path)

export PATH

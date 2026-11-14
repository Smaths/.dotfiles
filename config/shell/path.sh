# shellcheck shell=sh
# Shared POSIX PATH setup for Bash and login profiles.
_dot_path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

_dot_path_prepend "$HOME/bin"
_dot_path_prepend "$HOME/.local/bin"
_dot_path_prepend "$HOME/.config/mcp/bin"
_dot_path_prepend "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
export PATH
unset -f _dot_path_prepend

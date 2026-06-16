# Main bash entrypoint for this dotfiles repo.
# This file is intended for Debian server shells and should be symlinked to ~/.bashrc.

# Keep non-interactive shells quiet.
case $- in
  *i*) ;;
  *) return ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BASH_CONFIG_DIR="$DOTFILES_DIR/config/bash"

_dot_has() {
  command -v "$1" >/dev/null 2>&1
}

_dot_path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

_dot_path_prepend "$HOME/.local/bin"
_dot_path_prepend "$HOME/bin"
_dot_path_prepend "$HOME/.config/mcp/bin"
export PATH

# Prompt: green user/host, blue working directory, plain command text.
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '

# History tuned for long-lived server sessions.
export HISTFILE="${HISTFILE:-$HOME/.bash_history}"
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize
shopt -s cmdhist

# Aliases live in a dedicated file for easier maintenance.
if [ -r "$BASH_CONFIG_DIR/aliases.bash" ]; then
  # shellcheck source=config/bash/aliases.bash
  source "$BASH_CONFIG_DIR/aliases.bash"
fi

# fzf defaults. Debian names fd as fdfind.
if _dot_has fd; then
  _DOT_FD_COMMAND="fd"
elif _dot_has fdfind; then
  _DOT_FD_COMMAND="fdfind"
else
  _DOT_FD_COMMAND=""
fi

if [ -n "$_DOT_FD_COMMAND" ]; then
  export FZF_FD_EXCLUDE_ARGS='--exclude .git --exclude node_modules --exclude .cache --exclude dist --exclude build --exclude .next --exclude .turbo --exclude coverage --exclude target'
  export FZF_DEFAULT_COMMAND="$_DOT_FD_COMMAND -H -t f $FZF_FD_EXCLUDE_ARGS"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if _dot_has bat; then
  _DOT_FZF_PREVIEW='bat --style=numbers --color=always --line-range :160 {} 2>/dev/null || sed -n "1,160p" {}'
elif _dot_has batcat; then
  _DOT_FZF_PREVIEW='batcat --style=numbers --color=always --line-range :160 {} 2>/dev/null || sed -n "1,160p" {}'
else
  _DOT_FZF_PREVIEW='sed -n "1,160p" {}'
fi

export FZF_DEFAULT_OPTS="
  --height=70%
  --layout=reverse
  --border
  --extended
  --cycle
  --info=inline
  --preview-window=down:60%:wrap
  --preview 'p=\$([ -e {} ] && realpath {} || printf \"%s\" \"{}\"); printf \"%s\n\n\" \"\$p\"; [ -f {} ] && ($_DOT_FZF_PREVIEW)'
  --header-first
  --header 'enter: open | ctrl-y: copy path'
"

if [ -r /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  # shellcheck source=/usr/share/doc/fzf/examples/key-bindings.bash
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [ -r /usr/share/doc/fzf/examples/completion.bash ]; then
  # shellcheck source=/usr/share/doc/fzf/examples/completion.bash
  source /usr/share/doc/fzf/examples/completion.bash
fi

# Fuzzy-jump the directory stack (bash-native mirror of the zsh `d`/fstack helper).
# Bare `d` opens an fzf picker over `dirs -v`; `d 2` jumps straight to index 2.
# Note: bash only fills the stack via `pushd` (it has no zsh AUTO_PUSHD), so the
# stack stays small unless you push directories onto it.
d() {
  local line idx target

  if (($# > 0)); then
    idx="$1"
    [[ "$idx" =~ ^[0-9]+$ ]] || {
      printf 'Usage: d [stack-index]\n' >&2
      return 2
    }
    target="$(dirs -l "+$idx" 2>/dev/null)" || {
      printf 'd: no directory at stack index %s\n' "$idx" >&2
      return 1
    }
    builtin cd "$target" || return
    return
  fi

  command -v fzf >/dev/null 2>&1 || {
    printf 'd: fzf is required for interactive mode\n' >&2
    return 127
  }

  line="$(
    dirs -v | fzf --prompt='stack> ' --preview 'echo {}' --preview-window=hidden
  )" || return 1

  idx="${line#"${line%%[![:space:]]*}"}" # drop leading whitespace
  idx="${idx%%[[:space:]]*}"             # keep the leading index token
  [[ "$idx" =~ ^[0-9]+$ ]] || return 1
  target="$(dirs -l "+$idx" 2>/dev/null)" || return 1
  builtin cd "$target" || return
}

# Local machine overrides are opt-in and gitignored by convention.
if [ -r "$BASH_CONFIG_DIR/local.bash" ]; then
  # shellcheck source=/dev/null
  source "$BASH_CONFIG_DIR/local.bash"
fi

unset _DOT_FD_COMMAND _DOT_FZF_PREVIEW
unset -f _dot_has _dot_path_prepend

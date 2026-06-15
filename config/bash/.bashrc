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

# History tuned for long-lived server sessions.
export HISTFILE="${HISTFILE:-$HOME/.bash_history}"
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize
shopt -s cmdhist

# Listing and file safety.
alias ls='ls --color=auto'
alias l='ls -l'
alias ll='ls -lahF'
alias lls='ls -lahFtr'
alias la='ls -A'
alias lc='ls -CF'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias grep='grep -E -i --color=auto'

# Navigation.
alias dotfiles='cd "$HOME/.dotfiles"'
alias config='cd "$HOME/.config"'
alias work='cd "$HOME/workspace"'

# Git.
alias gs='git status'
alias gss='git status -s'
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph -n 40'
alias glol='git log --graph --abbrev-commit --oneline --decorate'
alias gp='git push'
alias gpof='git push origin --force-with-lease'
alias dif='git diff --no-index'

# Editors and terminal tools.
if _dot_has nvim; then
  alias vim='nvim'
  alias vi='nvim'
fi
alias svim='sudoedit'
if ! _dot_has bat && _dot_has batcat; then
  alias bat='batcat'
fi
alias batl='bat --paging=never -l log'

# System helpers.
alias restart='sudo reboot'
alias port='ss -tulpn | grep'
alias dust='du -sh * 2>/dev/null | sort -hr'
alias pg='ping 8.8.8.8'

# Tmux.
alias tmuxk='tmux kill-session -t'
alias tmuxa='tmux attach -t'
alias tmuxl='tmux list-sessions'

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

# Local machine overrides are opt-in and gitignored by convention.
if [ -r "$BASH_CONFIG_DIR/local.bash" ]; then
  # shellcheck source=/dev/null
  source "$BASH_CONFIG_DIR/local.bash"
fi

unset _DOT_FD_COMMAND _DOT_FZF_PREVIEW
unset -f _dot_has _dot_path_prepend

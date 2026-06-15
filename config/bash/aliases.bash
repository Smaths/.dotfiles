# Shell aliases for Debian server shells.
# Sourced from .bashrc; relies on the _dot_has helper defined there.

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

# Core aliases for macOS and general development.
_has() { command -v "$1" >/dev/null 2>&1; }

# Listing
if _has eza; then
  _eza='eza --group-directories-first --git --icons=auto'
  alias ls="$_eza"
  alias l="$_eza --long"
  alias ll="$_eza --long --all --header"
  alias lls="$_eza --long --all --header --sort=modified"
  alias la="$_eza --all"
  alias lc="$_eza --across --classify=auto"
  alias lt="$_eza --tree --level=2"
  unset _eza
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
  else
    alias ls='ls --color=auto'
  fi
  alias l='ls -l'
  alias ll='ls -lahF'
  alias lls='ls -lahFtr'
  alias la='ls -A'
  alias lc='ls -CF'
fi
[[ -x /usr/bin/time ]] && alias time='/usr/bin/time'

# Navigation
alias dev='cd "$HOME/Developer"'
alias doc='cd "$HOME/Documents"'
alias dow='cd "$HOME/Downloads"'
alias dotfiles='cd "$HOME/.dotfiles"'
alias config='cd "$HOME/.config"'
if [[ "$OSTYPE" == darwin* ]]; then
  alias icloud='cd "$HOME/Library/Mobile Documents/"'
fi
alias d='fstack'

# Git
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
alias gpo='git push origin'
alias gpof='git push origin --force-with-lease'
alias gpt='git push --tag'
alias gpraise='git blame'
alias gr='git remote'
alias grs='git remote show'
alias grb='git branch -r'
alias gplo='git pull origin'
alias gsub='git submodule update --remote'
alias dif='git diff --no-index'
if _has lazygit; then
  alias lg='lazygit'
fi

# Editors and terminal tools
if _has nvim; then
  alias vim='nvim'
  alias vi='nvim'
  alias nvimd='nvim --noplugin -u NONE'
fi
if _has bat; then
  alias batl='bat --paging=never -l log'
fi

# Docker inspection and compose helpers; never remove or prune resources here.
if _has docker; then
  alias dockls="docker container ls | awk 'NR > 1 {print \$NF}'"
  alias dockstats='docker stats'
  alias dockimg='docker images'
  if docker compose version >/dev/null 2>&1; then
    alias dockceu='docker compose run --rm -u $(id -u):$(id -g)'
    alias dockce='docker compose run --rm'
    alias docker-compose-dev='docker compose -f docker-compose-dev.yml'
  fi
fi

# Tmux
if _has tmux; then
  alias tmuxk='tmux kill-session -t'
  alias tmuxa='tmux attach -t'
  alias tmuxl='tmux list-sessions'
fi
if _has tmuxp; then
  alias mux='tmuxp load'
fi

# Small development helpers
if _has go; then
  alias gob='go build'
  alias gor='go run'
  alias gta='go test ./...'
fi
if _has hugo; then
  alias hugostart='hugo server -DEF --ignoreCache'
fi
if _has muffet; then
  alias deadlink='muffet -t 20'
fi
if _has extract; then
  alias ex='extract'
fi

unset -f _has

# Optional GitHub Copilot shortcuts
if command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
  copilot() {
    local t="$1"
    shift 2>/dev/null || true
    gh copilot suggest -t "$t" "$@"
  }
  alias '??'='copilot shell'
  alias 'git?'='copilot git'
  alias 'gh?'='copilot gh'
fi

alias 'dot-shell-update'='sh ~/.dotfiles/install/bootstrap.sh'

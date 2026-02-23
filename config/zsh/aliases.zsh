# macOS-safe baseline aliases
alias ls='ls -G'
alias l='ls -l'
alias ll='ls -lahF'
alias la='ls -A'

alias gs='git status'
alias gss='git status -s'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gp='git push'
alias gl='git log --oneline --decorate --graph'

alias vim='nvim'
alias vi='nvim'

# Optional Copilot aliases when extension exists.
if command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
  copilot() { local t="$1"; shift 2>/dev/null || true; gh copilot suggest -t "$t" "$@"; }
  alias '??'='copilot shell'
  alias 'git?'='copilot git'
  alias 'gh?'='copilot gh'
fi

# Optionally source legacy aliases for continuity.
[[ -r "$HOME/.dotfiles/aliases/aliases" ]] && source "$HOME/.dotfiles/aliases/aliases"

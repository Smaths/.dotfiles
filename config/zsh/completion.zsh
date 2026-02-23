# Homebrew and custom completion paths.
if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit
compinit -C

setopt AUTO_LIST
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
zmodload zsh/complist
zstyle ':completion:*' menu select=1
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

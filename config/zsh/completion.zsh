# Homebrew and custom completion paths. Login shells normally inherit this
# entry from `brew shellenv`; keep fpath unique when adding it as a fallback for
# interactive non-login shells.
typeset -gU fpath
if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit
# Keep the ownership/permission audit enabled even when .zcompdump exists.
compinit

setopt AUTO_LIST
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
zmodload zsh/complist

# fzf-tab replaces the completion menu with an fzf picker, and can only capture
# the unambiguous prefix while zsh's own menu is off. Keep the built-in menu on
# machines where the plugin is not cloned yet, so completion still degrades to
# arrow-key selection rather than a plain list.
if [[ -r "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  zstyle ':completion:*' menu no
else
  zstyle ':completion:*' menu select=1
fi

zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Group headings. fzf-tab renders these as its group labels and ignores color
# escapes in them, so this format is deliberately plain.
zstyle ':completion:*:descriptions' format '[%d]'
# Colorize candidates when the environment provides a palette.
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# git already returns checkout candidates in a meaningful order.
zstyle ':completion:*:git-checkout:*' sort false

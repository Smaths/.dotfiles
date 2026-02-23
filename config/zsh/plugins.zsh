# fzf
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# zsh-autocomplete (brew)
if command -v brew >/dev/null 2>&1; then
  autocomplete_script="$(brew --prefix zsh-autocomplete 2>/dev/null)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
  [[ -f "$autocomplete_script" ]] && source "$autocomplete_script"
fi

# zsh-syntax-highlighting should be loaded near the end of zsh init.
if command -v brew >/dev/null 2>&1; then
  zsh_sh="$(brew --prefix zsh-syntax-highlighting 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$zsh_sh" ]] && source "$zsh_sh"
fi

# OpenClaw completion.
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

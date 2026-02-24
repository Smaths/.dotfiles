# fzf
# Use ripgrep for fzf file listings (default and CTRL-T).
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# zsh-autocomplete (brew)
if command -v brew >/dev/null 2>&1; then
  autocomplete_script="$(brew --prefix zsh-autocomplete 2>/dev/null)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
  [[ -f "$autocomplete_script" ]] && source "$autocomplete_script"
fi

# zsh-autosuggestions (brew)
if command -v brew >/dev/null 2>&1; then
  autosuggest_script="$(brew --prefix zsh-autosuggestions 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$autosuggest_script" ]] && source "$autosuggest_script"
fi

# zsh-syntax-highlighting should be loaded near the end of zsh init.
if command -v brew >/dev/null 2>&1; then
  zsh_sh="$(brew --prefix zsh-syntax-highlighting 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$zsh_sh" ]] && source "$zsh_sh"
fi

# OpenClaw completion.
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

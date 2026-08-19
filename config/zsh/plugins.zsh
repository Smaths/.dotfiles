# Shell integrations and Zsh plugins.
# Sourced from .zshrc after completion.zsh, so compinit has already run --
# both fzf-tab and the zoxide completion depend on that ordering.

# -----------------------------------------------------------------------------
# Tool shell integrations
# -----------------------------------------------------------------------------
# fzf key bindings and completion: ctrl-r history, ctrl-t files, alt-c cd.
# fzf 0.48+ prints them with `fzf --zsh`; older builds only ship them as files.
if command -v fzf >/dev/null 2>&1; then
  _fzf_init="$(fzf --zsh 2>/dev/null)"
  if [[ -n "$_fzf_init" ]]; then
    eval "$_fzf_init"
  elif [[ -r "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
  else
    # First match wins so key bindings are never sourced twice.
    for _fzf_dir in \
      /opt/homebrew/opt/fzf/shell \
      /usr/local/opt/fzf/shell \
      /usr/share/doc/fzf/examples; do
      if [[ -r "$_fzf_dir/key-bindings.zsh" ]]; then
        source "$_fzf_dir/key-bindings.zsh"
        [[ -r "$_fzf_dir/completion.zsh" ]] && source "$_fzf_dir/completion.zsh"
        break
      fi
    done
    unset _fzf_dir
  fi
  unset _fzf_init
fi

# zoxide adds `z <partial>` and `zi` frecency jumps. `cd` is left alone on
# purpose, so AUTO_CD, CHASE_LINKS, and the directory stack keep working.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# OpenClaw completion.
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# -----------------------------------------------------------------------------
# Zsh plugins
# -----------------------------------------------------------------------------
# Cloned into $ZSH_PLUGIN_DIR by install/lib/zsh-plugins.sh. Every plugin is
# optional at runtime: a missing clone is skipped instead of erroring, so a
# machine that has not been bootstrapped yet still gets a working shell.
#
# The order below is load-bearing. fzf-tab has to load after compinit but before
# anything that wraps ZLE widgets, and fast-syntax-highlighting has to load last
# so it sees every widget the earlier plugins created.
_dotfiles_load_plugin() {
  local file="$ZSH_PLUGIN_DIR/$1/$1.plugin.zsh"
  [[ -r "$file" ]] || return 1
  source "$file"
}

if _dotfiles_load_plugin fzf-tab; then
  # fzf-tab does not inherit FZF_DEFAULT_OPTS, deliberately: that preview
  # command assumes a file argument, and some fzf flags break the plugin.
  zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border --cycle --info=inline
  zstyle ':fzf-tab:*' fzf-min-height 15
  zstyle ':fzf-tab:*' switch-group '<' '>'

  if command -v eza >/dev/null 2>&1; then
    _fzf_tab_dir_cmd='eza -1 --color=always --group-directories-first -- "$realpath"'
  else
    _fzf_tab_dir_cmd='ls -1 -- "$realpath"'
  fi
  if command -v bat >/dev/null 2>&1; then
    _fzf_tab_file_cmd='bat --style=numbers --color=always --line-range :160 -- "$realpath"'
  else
    _fzf_tab_file_cmd='sed -n "1,160p" "$realpath"'
  fi
  # Preview only real paths, so flag and branch completions stay uncluttered.
  zstyle ':fzf-tab:complete:*:*' fzf-preview \
    "if [[ -d \$realpath ]]; then $_fzf_tab_dir_cmd; elif [[ -f \$realpath ]]; then $_fzf_tab_file_cmd; fi"
  unset _fzf_tab_dir_cmd _fzf_tab_file_cmd
fi

_dotfiles_load_plugin zsh-autosuggestions

# Keep last.
_dotfiles_load_plugin fast-syntax-highlighting

unset -f _dotfiles_load_plugin

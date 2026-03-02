# Language/runtime environment.
export NVM_DIR="$HOME/.nvm"

# Lazy-load nvm and node tooling on first use to improve shell startup time.
if command -v brew >/dev/null 2>&1; then
  NVM_BREW_PREFIX="$(brew --prefix nvm 2>/dev/null || true)"
  NVM_SH="${NVM_BREW_PREFIX:+$NVM_BREW_PREFIX/nvm.sh}"
  NVM_COMPLETION_SH="${NVM_BREW_PREFIX:+$NVM_BREW_PREFIX/etc/bash_completion.d/nvm}"

  __load_nvm_once() {
    if [[ -n "${__NVM_LOADED:-}" ]]; then
      return 0
    fi

    [[ -s "$NVM_SH" ]] && source "$NVM_SH" --no-use
    [[ -s "$NVM_COMPLETION_SH" ]] && source "$NVM_COMPLETION_SH"

    __NVM_LOADED=1
  }

  nvm() {
    __load_nvm_once
    command nvm "$@"
  }

  for __nvm_cmd in node npm npx corepack; do
    eval "${__nvm_cmd}() { __load_nvm_once; command ${__nvm_cmd} \"\$@\"; }"
  done
  unset __nvm_cmd
fi

# Optional Herd support.
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"

# fzf
export FZF_FD_EXCLUDE_ARGS='--exclude .git --exclude node_modules --exclude .cache --exclude dist --exclude build --exclude .next --exclude .turbo --exclude coverage --exclude target'
export FZF_DEFAULT_COMMAND="fd -H -t f $FZF_FD_EXCLUDE_ARGS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='
  --height 70%
  --layout=reverse
  --border
  --extended
  --cycle
  --info=inline
  --preview-window=right:60%:wrap
  --preview 'p=$([ -e {} ] && realpath {} || printf "%s" "{}"); printf "%s\n\n" "$p"; [ -f {} ] && (bat --style=numbers --color=always --line-range :160 {} 2>/dev/null || sed -n "1,160p" {})' \
  --header-first \
  --header 'enter: open • ctrl-y: copy path'
'

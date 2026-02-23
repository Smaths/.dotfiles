# Language/runtime environment.
export NVM_DIR="$HOME/.nvm"
if command -v brew >/dev/null 2>&1; then
  [[ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]] && source "$(brew --prefix nvm)/nvm.sh"
  [[ -s "$(brew --prefix nvm 2>/dev/null)/etc/bash_completion.d/nvm" ]] && source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
fi

# Optional Herd support.
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"

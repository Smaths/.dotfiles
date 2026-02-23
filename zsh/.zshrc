# +--------+
# | PROMPT |
# +--------+
fpath=("$HOME/.config/prompt_purification" $fpath)
autoload -Uz prompt_purification_setup && prompt_purification_setup

# +------------+
# | NAVIGATION |
# +------------+
# Enable common navigation behavior.
setopt AUTO_CD            # Typing a directory name alone changes into it (no `cd` needed).
setopt AUTO_PUSHD         # Every `cd` pushes the previous directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS  # Prevent duplicate entries in the directory stack.
setopt PUSHD_SILENT       # Don't print the directory stack after pushd/popd/cd operations.
setopt PUSHD_TO_HOME      # `pushd` with no arguments goes to `$HOME`.
setopt PUSHD_MINUS        # Swap meanings of `+` and `-` in pushd/popd directory references.
# Optional typo correction for commands.
#setopt CORRECT           # Try to correct minor spelling mistakes in commands (can feel intrusive).
# Improve path handling and pattern support.
setopt CDABLE_VARS        # Treat undefined `cd <name>` targets as variable names containing paths.
setopt EXTENDED_GLOB      # Enable advanced glob patterns (e.g., `^`, `~`, `(#i)`, recursive matches).
# Follow symbolic links to their real target paths when changing directories.
setopt CHASE_LINKS        # Resolve symlinks so `$PWD` shows the physical directory path.


# +------------+
# | COMPLETION |
# +------------+
fpath=("$HOME/.zsh/zsh-completions/src" $fpath)
if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit
compinit -C

# Completion UX
setopt AUTO_LIST AUTO_MENU COMPLETE_IN_WORD
zmodload zsh/complist
zstyle ':completion:*' menu select=1
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# +---------+
# | HISTORY |
# +---------+
setopt EXTENDED_HISTORY       # Record timestamps and command duration in history.
setopt SHARE_HISTORY          # Share history immediately across all running zsh sessions.
setopt HIST_EXPIRE_DUPS_FIRST # When trimming history, remove duplicate entries first.
setopt HIST_IGNORE_DUPS       # Don't record a command if it matches the previous history entry.
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates when a command is re-entered.
setopt HIST_FIND_NO_DUPS      # Skip duplicate matches during history search.
setopt HIST_IGNORE_SPACE      # Don't record commands that start with a space.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate history entries to the history file.
setopt HIST_VERIFY            # Load history expansion into the command line before execution.

# +--------------+
# | PLUGINS      |
# +--------------+
# zsh-bd
BD_PLUGIN_PATH="$HOME/.zsh/plugins/bd/bd.zsh"
if [[ -f "$BD_PLUGIN_PATH" ]]; then
  source "$BD_PLUGIN_PATH"
elif [[ -o interactive ]]; then
  mkdir -p "${BD_PLUGIN_PATH:h}"
  if command -v curl >/dev/null 2>&1 &&
     curl -fsSL "https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh" -o "$BD_PLUGIN_PATH"; then
    source "$BD_PLUGIN_PATH"
  fi
fi

# zsh-autocomplete
if command -v brew >/dev/null 2>&1; then
  autocomplete_script="$(brew --prefix zsh-autocomplete 2>/dev/null)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
  [[ -f "$autocomplete_script" ]] && source "$autocomplete_script"
fi

# fzf
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# OpenClaw completion
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# +---------+
# | ALIASES |
# +---------+
source "$HOME/.config/aliases/aliases"

if command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
  copilot() { local t="$1"; shift 2>/dev/null || true; gh copilot suggest -t "$t" "$@"; }
  alias '??'='copilot shell'
  alias 'git?'='copilot git'
  alias 'gh?'='copilot gh'
fi

# +---------------------+
# | ENVIRONMENT         |
# +---------------------+
export NVM_DIR="$HOME/.nvm"
[[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] && . "/opt/homebrew/opt/nvm/nvm.sh"
[[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

# +---------------------+
# | SYNTAX HIGHLIGHTING |
# +---------------------+
if command -v brew >/dev/null 2>&1; then
  zsh_sh="$(brew --prefix zsh-syntax-highlighting 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$zsh_sh" ]] && source "$zsh_sh"
fi
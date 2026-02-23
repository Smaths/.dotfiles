# Prompt (fallback to starship if available)
if [[ -r "$HOME/.config/prompt_purification/prompt_purification_setup" ]]; then
  fpath=("$HOME/.config/prompt_purification" $fpath)
  autoload -Uz prompt_purification_setup && prompt_purification_setup
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Navigation
DIRSTACKSIZE=11            # Keep up to 10 entries in the directory stack.
setopt AUTO_CD             # Entering a directory name alone runs `cd <dir>`.
setopt AUTO_PUSHD          # `cd` pushes previous directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS   # Do not store duplicate directories in the stack.
setopt PUSHD_SILENT        # Suppress automatic directory stack printing after pushd/popd/cd.
setopt PUSHD_TO_HOME       # `pushd` with no args goes to $HOME.
setopt PUSHD_MINUS         # Swap `+` and `-` meanings in stack references for pushd/popd.
setopt CDABLE_VARS         # Allow `cd` to use shell variables as directory names.
setopt EXTENDED_GLOB       # Enable advanced globbing features and glob qualifiers.
setopt CHASE_LINKS         # Resolve symlinks to their real path when changing directories.

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"  # Location of the history file on disk.
HISTSIZE=100000                    # Number of history entries kept in memory.
SAVEHIST=100000                    # Number of history entries saved to HISTFILE.
setopt EXTENDED_HISTORY            # Record timestamps and command duration in history.
setopt SHARE_HISTORY               # Share history across all running zsh sessions.
setopt HIST_EXPIRE_DUPS_FIRST      # Remove duplicate commands first when trimming history.
setopt HIST_IGNORE_DUPS            # Ignore a command if it's the same as the previous one.
setopt HIST_IGNORE_ALL_DUPS        # Remove older duplicate entries when adding a new command.
setopt HIST_FIND_NO_DUPS           # Skip duplicate entries during history search.
setopt HIST_IGNORE_SPACE           # Do not save commands that start with a space.
setopt HIST_SAVE_NO_DUPS           # Avoid writing duplicate commands to the history file.
setopt HIST_VERIFY                 # Load history expansion into the prompt for review before run.

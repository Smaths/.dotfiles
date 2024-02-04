# +------------+
# | NAVIGATION |
# +------------+

setopt AUTO_CD              # Go to folder path without using cd.

setopt AUTO_PUSHD           # Push the old directory onto the stack on cd.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

setopt CORRECT              # Spelling correction
setopt CDABLE_VARS          # Change directory to a path stored in a variable.
setopt EXTENDED_GLOB        # Use extended globbing syntax.

#source $DOTFILES/zsh/plugins/bd.zsh

# +---------+
# | HISTORY |
# +---------+

setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.

# +---------+
# | ALIASES |
# +---------+

source $DOTFILES/aliases/aliases

# Check if the gh copilot extension is installed and load aliases accordingly
if gh extension list | grep -q 'github/gh-copilot'; then
  copilot_shell_suggest() {
    gh copilot suggest -t shell "$@"
  }
  alias '??'='copilot_shell_suggest'

  # Function to handle Git command suggestions
  copilot_git_suggest() {
    gh copilot suggest -t git "$@"
  }
  alias 'git?'='copilot_git_suggest'

  # Function to handle GitHub CLI command suggestions
  copilot_gh_suggest() {
    gh copilot suggest -t gh "$@"
  }
  alias 'gh?'='copilot_gh_suggest'
fi

# +--------+
# | PROMPT |
# +--------+

fpath=(/Users/snarfum/.config/iterm2/purification $fpath)
autoload -Uz prompt_purification_setup && prompt_purification_setup

# +------------+
# | COMPLETION |
# +------------+

fpath=(~/.zsh/zsh-completions/src $fpath)
autoload -U compinit; compinit
 
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

# +--------------+
# | autocomplete |
# +--------------+

source /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# +-----+
# | FZF |
# +-----+

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# +--------------------------+
# | iTerm2 Shell Integration |
# +--------------------------+

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# +---------------------+
# | Node Version Manager|
# +---------------------+
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# +------+
# | Ruby |
# +------+

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh
chruby ruby-3.2.2

# +---------------------+
# | SYNTAX HIGHLIGHTING |
# +---------------------+

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
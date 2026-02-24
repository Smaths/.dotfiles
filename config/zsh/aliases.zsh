# -----------------------------------------------------------------------------
# Core shell / listing
# -----------------------------------------------------------------------------
alias ls='ls -G'
alias l='ls -l'
alias ll='ls -lahF'
alias lls='ls -lahFtr'
alias la='ls -A'
alias lc='ls -CF'

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias grep='grep -E -i --color=auto'
alias time='/usr/bin/time'

# -----------------------------------------------------------------------------
# Directory navigation
# -----------------------------------------------------------------------------
alias dev='cd $HOME/Developer'
alias doc='cd $HOME/Documents'
alias dow='cd $HOME/Downloads'
alias config='cd $HOME/.config'
alias icloud='cd $HOME/Library/Mobile\ Documents/'
alias work='cd $HOME/workspace'

# Directory stack (recent dirs)
alias d='dirs -v | sed -n "1,10p"'

# After running `d`, type `0`..`9` as the next command to jump to that entry.
# Note: `0` is current directory, so it is effectively a no-op.
for i in {0..9}; do
  # PUSHD_MINUS is enabled in options.zsh, so use -N to match dirs -v indices.
  eval "$i() { builtin cd '-$i' >/dev/null; }"
done
unset i

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias gs='git status'
alias gss='git status -s'
alias ga='git add'
alias gb='git branch '
alias gc='git commit'
alias gco='git checkout '
alias gd='git diff'
alias gl='git log --oneline --decorate --graph'
alias glol='git log --graph --abbrev-commit --oneline --decorate'
alias gp='git push'
alias gpo='git push origin'
alias gpof='git push origin --force-with-lease'
alias gpofn='git push origin --force-with-lease --no-verify'
alias gpt='git push --tag'
alias gpraise='git blame'
alias gr='git remote'
alias grs='git remote show'
alias grb='git branch -r'
alias gplo='git pull origin'
alias gsub='git submodule update --remote'
alias gj='git-jump'
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'
alias dif='git diff --no-index'
alias gclean="git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d"
alias gblog="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:red)%(refname:short)%(color:reset) - %(color:yellow)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:blue)%(committerdate:relative)%(color:reset))'"

# -----------------------------------------------------------------------------
# Editors / terminal tools
# -----------------------------------------------------------------------------
alias vim='nvim'
alias vi='nvim'
alias svim='sudoedit'
alias dvim='vim -u /usr/share/nvim/archlinux.vim'
alias nvimc='rm -I $VIMCONFIG/swap/*'
alias nvimcu='rm -I $VIMCONFIG/undo/*'
alias nviml='nvim -w $VIMCONFIG/vimlog "$@"'
alias nvimd='nvim --noplugin -u NONE'
alias nvimfr='nvim +e /tmp/scratchpad.md -c "set spelllang=fr"'
alias lvim='\vim -c "set nowrap|syntax off"'
alias kitty='kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty'
alias batl='bat --paging=never -l log'

# -----------------------------------------------------------------------------
# Network / system helpers
# -----------------------------------------------------------------------------
alias shutdown='sudo shutdown now'
alias restart='sudo reboot'
alias suspend='sudo pm-suspend'
alias bigf='find / -xdev -type f -size +500M'
alias xpropc='xprop | grep WM_CLASS'
alias cb='xclip -sel clip'
alias dust='du -sh * | sort -hr'
alias pg='ping 8.8.8.8'
alias port='netstat -tulpn | grep'
alias fonts='fc-cache -f -v'
alias wifi='sudo wifi-menu -o'
alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'

# -----------------------------------------------------------------------------
# Package managers (Linux-centric legacy)
# -----------------------------------------------------------------------------
alias paci='sudo pacman -S'
alias pachi='sudo pacman -Ql'
alias pacs='sudo pacman -Ss'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -R'
alias pacrr='sudo pacman -Rs'
alias pacrc='sudo pacman -Sc'
alias pacro='pacman -Rns $(pacman -Qtdq)'
alias pacrl='rm /var/lib/pacman/db.lck'
alias pacls='sudo pacman -Qe'
alias pacc='sudo pacman -Sc'
alias paccc='sudo pacman -Scc'

alias yayi='yay -S'
alias yayhi='yay -Ql'
alias yays='yay -Ss'
alias yayu='yay -Syu'
alias yayr='yay -R'
alias yayrr='yay -Rs'
alias yayrc='yay -Sc'
alias yayls='yay -Qe'

alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

# -----------------------------------------------------------------------------
# Language / dev tools
# -----------------------------------------------------------------------------
alias gob='go build'
alias gor='go run'
alias goc='go clean -i'
alias gta='go test ./...'
alias gia='go install ./...'
alias gosrc='$GOPATH/src/'
alias gobin='$GOPATH/bin/'

alias hugostart='hugo server -DEF --ignoreCache'
alias deadlink='muffet -t 20'
alias cljrepl='clojure -Sdeps "{:deps {com.bhauman/rebel-readline {:mvn/version \"0.1.4\"}}}" -m rebel-readline.main'
alias awsa='aws --profile amboss-profile'

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dockls="docker container ls | awk 'NR > 1 {print \$NF}'"
alias dockRr='docker rm $(docker ps -a -q)'
alias dockstats='docker stats $(docker ps -q)'
alias dockimg='docker images'
alias dockprune='docker system prune -a'
alias dockceu='docker-compose run --rm -u $(id -u):$(id -g)'
alias dockce='docker-compose run --rm'
alias docker-compose-dev='docker-compose -f docker-compose-dev.yml'

# -----------------------------------------------------------------------------
# Tmux / session tools
# -----------------------------------------------------------------------------
alias tmuxk='tmux kill-session -t'
alias tmuxa='tmux attach -t'
alias tmuxl='tmux list-sessions'
alias mux='tmuxp load'

# -----------------------------------------------------------------------------
# Misc workflow helpers
# -----------------------------------------------------------------------------
alias lynx='lynx -vikeys -accept_all_cookies'
alias ubackup='udiskie-umount $MEDIA/BACKUP'
alias umedia='udiskie-umount $MEDIA/*'
alias freebrain='freemind $CLOUD/knowledge_base/_BRAINSTORMING/*.mm &> /dev/null &'
alias freelists='freemind $CLOUD/knowledge_base/_LISTS/*.mm &> /dev/null &'
alias freepain='freemind $CLOUD/knowledge_base/_PROBLEMS/*.mm &> /dev/null &'
alias freeproj='freemind $CLOUD/knowledge_base/_PROJECTS/*.mm &> /dev/null &'
alias obsn='prime-run obs&'
alias mke='mkextract'
alias ex='extract'
alias ddg='duckduckgo'
alias wiki='wikipedia'
alias calc='noglob calcul'

# -----------------------------------------------------------------------------
# Optional GitHub Copilot shortcuts
# -----------------------------------------------------------------------------
if command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
  copilot() { local t="$1"; shift 2>/dev/null || true; gh copilot suggest -t "$t" "$@"; }
  alias '??'='copilot shell'
  alias 'git?'='copilot git'
  alias 'gh?'='copilot gh'
fi

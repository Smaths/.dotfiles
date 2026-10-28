# Language/runtime environment.
# mise is activated through its shims in path.zsh, not `mise activate`, so
# non-zsh and non-interactive processes resolve the same runtimes. Its config
# is read from the XDG default path, symlinked to config/mise/config.toml.

# Optional Herd support.
if [[ "$OSTYPE" == darwin* ]]; then
  export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
  export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
fi

# fzf: Debian packages fd-find as fdfind; macOS and other platforms use fd.
if (($+commands[fd])); then
  export FZF_FD_COMMAND=fd
elif (($+commands[fdfind])); then
  export FZF_FD_COMMAND=fdfind
else
  export FZF_FD_COMMAND=fd
fi
export FZF_FD_EXCLUDE_ARGS='--exclude .git --exclude node_modules --exclude .cache --exclude dist --exclude build --exclude .next --exclude .turbo --exclude coverage --exclude target'
export FZF_DEFAULT_COMMAND="$FZF_FD_COMMAND -H -t f $FZF_FD_EXCLUDE_ARGS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="
  --height=70%
  --layout=reverse
  --border
  --extended
  --cycle
  --info=inline
  --preview-window=down:60%:wrap
  --preview 'p=\$([ -e {} ] && realpath {} || printf \"%s\" \"{}\"); printf \"%s\n\n\" \"\$p\"; [ -f {} ] && (bat --style=numbers --color=always --line-range :160 {} 2>/dev/null || sed -n \"1,160p\" {})'
  --header-first
  --header 'enter: open | ctrl-y: copy path'
"

# 1Password SSH agent.
# Export only when the agent socket exists so non-1Password environments degrade safely.
_ONEPASSWORD_SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [[ -S "$_ONEPASSWORD_SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="$_ONEPASSWORD_SSH_AUTH_SOCK"
fi
unset _ONEPASSWORD_SSH_AUTH_SOCK

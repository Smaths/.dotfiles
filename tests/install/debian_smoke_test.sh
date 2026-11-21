#!/usr/bin/env bash
# Run as root in a disposable Debian/Ubuntu container: this installs apt packages.
set -euo pipefail

if ((EUID != 0)); then
  printf 'Run this test as root in a disposable Debian/Ubuntu container.\n' >&2
  exit 1
fi

repo_dir="$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)"
bootstrap=(sh "$repo_dir/install/bootstrap.sh")
home_dir="$(mktemp -d)"
export HOME="$home_dir" TERM=xterm-256color
unset DEBIAN_FRONTEND
trap 'rm -rf "$home_dir"' EXIT

printf '# original bashrc\n' >"$HOME/.bashrc"
printf '# original tmux config\n' >"$HOME/.tmux.conf"

"${bootstrap[@]}" --dry-run --skip-packages
[[ ! -L "$HOME/.bashrc" && ! -L "$HOME/.tmux.conf" ]]
[[ $(<"$HOME/.bashrc") == '# original bashrc' ]]
[[ $(<"$HOME/.tmux.conf") == '# original tmux config' ]]

"${bootstrap[@]}" --yes </dev/null 2>&1 | tee "$HOME/install.log"
if grep -Eq 'Configuring tzdata|debconf: (unable to initialize|falling back)' "$HOME/install.log"; then
  printf 'apt tried to use an interactive debconf frontend with --yes\n' >&2
  exit 1
fi
[[ $(readlink "$HOME/.bashrc") == "$repo_dir/config/bash/.bashrc" ]]
[[ $(readlink "$HOME/.tmux.conf") == "$repo_dir/config/tmux/tmux.conf" ]]

# A held package is still installed and must not trigger another apt run.
printf 'fzf hold\n' | dpkg --set-selections
rerun=$("${bootstrap[@]}" --yes </dev/null)
printf '%s\n' "$rerun"
grep -Fq 'all packages already installed' <<<"$rerun"
shopt -s nullglob
bash_backups=("$HOME"/.bashrc.bak.*)
tmux_backups=("$HOME"/.tmux.conf.bak.*)
[[ ${#bash_backups[@]} == 1 && ${#tmux_backups[@]} == 1 ]]
[[ $(<"${bash_backups[0]}") == '# original bashrc' ]]
[[ $(<"${tmux_backups[0]}") == '# original tmux config' ]]

bash -eic '
  alias ll
  [[ $FZF_DEFAULT_COMMAND == fdfind\ * ]]
  [[ $(printf "sample\n" | fzf --filter sample) == sample ]]
  dotfiles
  [[ -f install/bootstrap.sh ]]
' </dev/null

# Isolate tmux from any other server and verify it read the linked config.
tmux -S "$HOME/tmux.sock" new-session -d
[[ $(tmux -S "$HOME/tmux.sock" show-options -gv prefix) == C-a ]]
tmux -S "$HOME/tmux.sock" kill-server
printf 'ok - Debian/Ubuntu bootstrap install and rerun\n'

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
export HOME="$home_dir" TERM=xterm-256color TEST_REPO_DIR="$repo_dir"
export XDG_CONFIG_HOME="$HOME/xdg-config" XDG_DATA_HOME="$HOME/xdg-data"
unset DEBIAN_FRONTEND DOTFILES_DIR ZDOTDIR MISE_CONFIG_DIR MISE_DATA_DIR MISE_GLOBAL_CONFIG_FILE
trap 'rm -rf "$home_dir"' EXIT

user=$(id -un)
login_shell() { getent passwd "$user" | cut -d: -f7; }
original_shell=$(login_shell)
files=(.bashrc .zprofile .zshrc .tmux.conf)
for file in "${files[@]}"; do
  printf 'original %s\n' "$file" >"$HOME/$file"
done

# A clean system can preview the shell change without installing packages.
plan=$("${bootstrap[@]}" --dry-run --skip-packages --force-shell)
printf '%s\n' "$plan"
grep -Fq 'change current user to Zsh if needed' <<<"$plan"
grep -Fq '[dry-run] chsh -s ' <<<"$plan"
[[ $(login_shell) == "$original_shell" && ! -e "$XDG_DATA_HOME" ]]
for file in "${files[@]}"; do
  [[ ! -L "$HOME/$file" && $(<"$HOME/$file") == "original $file" ]]
done

# Preview the default dev setup on a clean machine without making changes.
plan=$("${bootstrap[@]}" --dry-run)
grep -Fq "mise: install from https://mise.run to $HOME/.local/bin/mise" <<<"$plan"
grep -Fq "Pi: link $XDG_CONFIG_HOME/mise/conf.d/dotfiles-debian.toml" <<<"$plan"
[[ ! -e "$HOME/.local" && ! -e "$XDG_CONFIG_HOME" && ! -e "$XDG_DATA_HOME" ]]
plan=$("${bootstrap[@]}" --dry-run --skip-mise)
grep -Fq 'apt packages: install missing entries only' <<<"$plan"
grep -Fq 'mise and Pi: skipped' <<<"$plan"

# Preview a custom startup directory without creating it.
custom_dir="$HOME/custom Zsh"
plan=$(ZDOTDIR="$custom_dir" "${bootstrap[@]}" --dry-run --skip-packages)
grep -Fq "$custom_dir/.zshrc" <<<"$plan"
grep -Fq "$custom_dir/.zprofile" <<<"$plan"
[[ ! -e "$custom_dir" ]]
# An exported empty ZDOTDIR is not the same as unsetting it in Zsh.
for invalid_dir in '' relative; do
  if plan=$(ZDOTDIR="$invalid_dir" "${bootstrap[@]}" --dry-run --skip-packages --force-shell 2>&1); then
    printf 'bootstrap accepted an invalid ZDOTDIR: %q\n' "$invalid_dir" >&2
    exit 1
  fi
  grep -Fq 'Zsh startup directory (ZDOTDIR or HOME) must be absolute' <<<"$plan"
done

# Slim images can exclude /usr/share/doc. Older fzf packages put their Zsh
# bindings there; include those files to exercise the real legacy fallback.
printf '%s\n' 'path-include=/usr/share/doc/fzf/examples/*' >/etc/dpkg/dpkg.cfg.d/zz-dotfiles-test
# Keep existing global settings, and do not install tools from them or from
# the caller's project. Pi must come from the managed baseline.
mkdir -p "$XDG_CONFIG_HOME/mise" "$HOME/project"
printf '[tools]\nnode = "22"\n' >"$XDG_CONFIG_HOME/mise/config.toml"
printf '[tools]\npi = "0.1.0"\n' >"$HOME/project/mise.toml"
(cd "$HOME/project" && "${bootstrap[@]}" --yes </dev/null) 2>&1 | tee "$HOME/install.log"
if grep -Eq 'Configuring tzdata|debconf: (unable to initialize|falling back)' "$HOME/install.log"; then
  printf 'apt tried to use an interactive debconf frontend with --yes\n' >&2
  exit 1
fi
[[ $(login_shell) == "$original_shell" ]]
[[ $(readlink "$HOME/.zshrc") == "$repo_dir/config/zsh/.zshrc" ]]
[[ $(readlink "$HOME/.zprofile") == "$repo_dir/config/zsh/.zprofile" ]]
[[ $(readlink "$HOME/.tmux.conf") == "$repo_dir/config/tmux/tmux.conf" ]]
[[ -x "$HOME/.local/bin/mise" ]]
[[ $(readlink "$XDG_CONFIG_HOME/mise/conf.d/dotfiles-debian.toml") == "$repo_dir/install/platforms/debian/mise.toml" ]]
[[ ! -L "$XDG_CONFIG_HOME/mise/config.toml" ]]
grep -Fxq 'node = "22"' "$XDG_CONFIG_HOME/mise/config.toml"
[[ $(find "$XDG_DATA_HOME/mise/installs" -mindepth 1 -maxdepth 1 -type d -printf '%f\n') == pi ]]

# A held package is still installed and must not trigger another apt run.
printf 'fzf hold\n' | dpkg --set-selections
rerun=$("${bootstrap[@]}" --yes </dev/null)
printf '%s\n' "$rerun"
grep -Fq 'all packages already installed' <<<"$rerun"
grep -Fq "mise: reuse $HOME/.local/bin/mise" <<<"$rerun"
grep -Fq '0 cloned, 0 updated, 3 current' <<<"$rerun"
shopt -s nullglob
bash_backups=("$HOME"/.bashrc.bak.*)
[[ ${#bash_backups[@]} == 0 && ! -L "$HOME/.bashrc" && $(<"$HOME/.bashrc") == 'original .bashrc' ]]
for file in .zprofile .zshrc .tmux.conf; do
  backups=("$HOME/$file".bak.*)
  [[ ${#backups[@]} == 1 && $(<"${backups[0]}") == "original $file" ]]
done

# Live startup from a non-default checkout, with shared tools and plugins loaded.
zsh -lic '
  [[ $DOTFILES_DIR == "$TEST_REPO_DIR" && $path[(Ie)$HOME/.local/bin] -gt 0 ]] || exit 1
  [[ $(command -v mise) == "$HOME/.local/bin/mise" ]] || exit 1
  [[ $(command -v pi) == "$XDG_DATA_HOME/mise/shims/pi" ]] || exit 1
  pi_version=$(pi --version) || exit 1
  [[ -n "$pi_version" && "$pi_version" == "$(mise current pi)" && "$pi_version" != 0.1.0 ]] || exit 1
  (( $+aliases[ll] && $+functions[fcd] )) || exit 1
  whence -w z >/dev/null || exit 1
  (( $+functions[prompt_purification_setup] && $+functions[_zsh_autosuggest_start] )) || exit 1
  whence -w -- -fast-highlight-process >/dev/null || exit 1
  (( $+widgets[fzf-tab-complete] )) || exit 1
  [[ $FZF_DEFAULT_COMMAND == fdfind\ * && $ZSH_BAT_COMMAND == (bat|batcat) ]] || exit 1
  command -v "$ZSH_BAT_COMMAND" >/dev/null || exit 1
  [[ $(printf "sample\n" | fzf --filter sample) == sample ]] || exit 1
  dotfiles
  [[ $PWD == "$TEST_REPO_DIR" ]]
' </dev/null
# fzf keybindings need a PTY. This exercises both modern and packaged legacy init.
script -qec 'zsh -ic "(( \$+widgets[fzf-history-widget] ))"' /dev/null </dev/null

# Linking into a custom ZDOTDIR must work from a fresh home without remote Git
# access. Simulate a persistent ZDOTDIR via the new home's .zshenv.
offline_home="$HOME/offline"
offline_zdotdir="$offline_home/custom Zsh"
mkdir -p "$offline_home"
printf 'export ZDOTDIR=%q\n' "$offline_zdotdir" >"$offline_home/.zshenv"
HOME="$offline_home" ZDOTDIR="$offline_zdotdir" XDG_CONFIG_HOME='' XDG_DATA_HOME='' GIT_ALLOW_PROTOCOL='' \
  "${bootstrap[@]}" --yes --skip-packages --skip-plugins </dev/null
[[ ! -e "$offline_home/.local" && ! -e "$offline_home/.config/mise" ]]
[[ ! -e "$offline_home/.zshrc" && ! -e "$offline_home/.zprofile" ]]
[[ $(readlink "$offline_zdotdir/.zshrc") == "$repo_dir/config/zsh/.zshrc" ]]
[[ $(readlink "$offline_zdotdir/.zprofile") == "$repo_dir/config/zsh/.zprofile" ]]
[[ $(readlink "$offline_home/.tmux.conf") == "$repo_dir/config/tmux/tmux.conf" ]]
HOME="$offline_home" XDG_DATA_HOME='relative' zsh -lic '
  [[ $DOTFILES_DIR == "$TEST_REPO_DIR" && -n $aliases[ll] && -z $widgets[fzf-tab-complete] &&
     $ZSH_PLUGIN_DIR == "$HOME/.local/share/zsh/plugins" ]]
' </dev/null

# Changing the account shell is opt-in and a second opt-in run is a no-op.
"${bootstrap[@]}" --yes --skip-packages --force-shell </dev/null
[[ $(readlink -f "$(login_shell)") == "$(readlink -f "$(command -v zsh)")" ]]
rerun=$("${bootstrap[@]}" --yes --skip-packages --force-shell --upgrade-plugins </dev/null)
grep -Fq "already $(login_shell)" <<<"$rerun"
grep -Fq '0 cloned, 0 updated, 3 current' <<<"$rerun"

# Isolate tmux from any other server and verify it read the linked config.
tmux -S "$HOME/tmux.sock" new-session -d
[[ $(tmux -S "$HOME/tmux.sock" show-options -gv prefix) == C-a ]]
tmux -S "$HOME/tmux.sock" kill-server
printf 'ok - Debian/Ubuntu bootstrap install and rerun\n'

# Operations

## Install (Fresh Machine)

```zsh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

Windows:

```powershell
git clone https://github.com/Smaths/.dotfiles.git $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap.ps1
```

Debian server:

```bash
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

Useful flags:

- `--dry-run`: print intended actions without mutating.
- `--yes`: run without interactive confirmation on macOS, Windows, and Debian.
- `--verbose`: show extra command detail.
- `--upgrade-packages` (macOS only): upgrade outdated selected Brewfile entries
  during bootstrap.
- `--creative` (macOS only): also install the optional creative/audio casks in
  `Brewfile.creative`; the default installs the core Brewfile only.
- `--skip-packages` (Windows only): skip `winget` installs.
- Windows does not support native shell linking; the retired `--link-windows-shell` option is rejected. Use the Debian/Ubuntu bootstrap inside WSL.
- `--skip-packages` (Debian only): skip `apt-get` installs.
- `--force-shell` (Debian only): change the current user's login shell to bash.

Interactive runs print a preflight plan and ask for confirmation before
mutation. Noninteractive mutation requires `--yes`; otherwise use `--dry-run`
to inspect the plan.

macOS settings are separate from bootstrap. Run them explicitly when wanted:

```zsh
zsh ~/.dotfiles/install/platforms/macos/settings.zsh
```

The settings script offers three modes:

- `1) Use defaults (no per-setting prompts)`: applies repo defaults after confirmation.
- `2) Choose settings`: set defaults for each setting, then proceed.
- `3) Skip`: exits macOS tuning without applying defaults.

Creative and audio applications are skipped by the default development
workstation bootstrap. Include the optional cask set on a machine that needs it:

```zsh
sh ~/.dotfiles/install/bootstrap.sh --creative
```

To install only that manifest without running the rest of bootstrap:

```zsh
brew bundle install --no-upgrade \
  --file ~/.dotfiles/install/platforms/macos/Brewfile.creative
```

Ableton Live is intentionally absent from both manifests and should be installed
and updated directly from Ableton. The creative manifest installs Unity Hub, but
not Homebrew's rolling `unity` editor cask. Install each project's exact editor
through Hub or the Unity CLI using its
`ProjectSettings/ProjectVersion.txt`. The optional manifest is independent for
installation only: cleanup against either manifest treats entries from the other
as unlisted. Preview any `brew bundle cleanup` operation carefully and compare it
against both manifests before considering `--force`.

## Update (Existing Machine)

```zsh
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh
```

The macOS bootstrap checks the Brewfile first and skips `brew bundle install`
when all entries are already present. When installation is needed, it uses
`brew bundle install --verbose --no-upgrade --jobs=auto` so reruns install
missing entries without turning every bootstrap into a full Homebrew upgrade
pass. Verbose Bundle output streams the underlying Homebrew commands while up
to four formula installations run in parallel, so the terminal continues to
show activity after the initial fetch phase. Parallel output can interleave.
When installation is needed, Brew Bundle and mise run in the foreground with
their native output and signal handling; bootstrap does not background them or
redirect their output to temporary logs.
Prompt Purification requires no separate install step. It is vendored under
`config/zsh/prompts/purification/`, and the linked `~/.zshrc` loads that tracked
copy. Bootstrap validates the prompt file before relinking shell configuration.
After Brew Bundle completes, the bootstrap symlinks `config/mise/config.toml` to
`${XDG_CONFIG_HOME:-~/.config}/mise/config.toml` and then runs `mise install` to
install or verify the pinned Go, Node.js, Pi, and pnpm versions. Because the
config sits at the path mise reads by default, no environment variable is needed.
Go 1.27, Node.js 24, and pnpm 11 are the defaults, and mise provides the pinned
`pi` terminal agent. Project mise configs, `.nvmrc`, `.node-version`, and
`packageManager` files remain the source of truth for selecting other versions
through mise. The shims are added by the managed Zsh login PATH; GUI apps and
arbitrary non-shell processes do not necessarily inherit that PATH.

Bootstrap also symlinks `config/uv/uv.toml` to
`${XDG_CONFIG_HOME:-~/.config}/uv/uv.toml`. uv uses only uv-managed Python
interpreters for projects and Python-package tools; Apple/Xcode Python and its
user package directory are not modified or added to `PATH`. Standalone native
applications such as the official OpenAI CLI are installed through Homebrew.

Zsh plugins follow the same policy as Brewfile entries. Bootstrap clones any
missing plugin from `install/lib/zsh-plugins.sh` on every run, but only
fast-forwards existing clones when `--upgrade-packages` is passed. A clone with
local commits fails the fast-forward loudly rather than being merged or reset,
and a plugin directory that is not a git clone is reported and left alone.

To intentionally upgrade outdated Homebrew packages and casks during bootstrap:

```zsh
sh install/bootstrap.sh --upgrade-packages
```

For unattended maintenance, pass `--yes` explicitly:

```zsh
sh install/bootstrap.sh --yes
```

Go, Node.js, Pi, and pnpm upgrades are intentional config changes rather than
side effects of a Homebrew upgrade. Update the defaults, review the diff, then
rerun bootstrap. Keep project runtime and package-manager pins until their
projects are tested on newer versions.

Pi is installed as a standalone executable, so `pi update` cannot replace the
executable and may report its internal Bun path (`/$bunfs/root/pi`). Update the
Pi pin in `config/mise/config.toml` and run `mise install` instead. Use
`pi update --extensions` only to update configured Pi extensions.

```zsh
${EDITOR:-vi} ~/.dotfiles/config/mise/config.toml
mise install
sh install/bootstrap.sh
```

Check the versions selected in a project directory before installing
dependencies:

```zsh
mise current
go version
node --version
npm --version   # npm projects
pnpm --version  # pnpm projects
pi --version
```

Windows update flow:

```powershell
Set-Location $HOME/.dotfiles
git pull --ff-only
powershell -ExecutionPolicy Bypass -File install/bootstrap.ps1 --skip-packages
```

Debian update flow:

```bash
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh --skip-packages
```

Without `--skip-packages`, Debian bootstrap checks `install/platforms/debian/apt-packages.txt`
first and skips `apt-get update`/`apt-get install` when every manifest package
is already installed. If packages are missing, it updates apt metadata and
installs only the missing package names.

## Doctor (Health Checks)

Manual checks:

```zsh
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
brew bundle check --no-upgrade --file ~/.dotfiles/install/platforms/macos/Brewfile
test -L ~/.config/mise/config.toml && readlink ~/.config/mise/config.toml
mise current
go version
node --version
pnpm --version
pi --version
test -L ~/.config/uv/uv.toml && readlink ~/.config/uv/uv.toml
uv python list --only-installed
openai --version
# Apple/Xcode Python remains available, but its user scripts are not global.
/usr/bin/python3 --version
zsh -lc '[[ ":$PATH:" != *":$HOME/Library/Python/3.9/bin:"* ]]'
# A child process launched from this configured login shell inherits its PATH.
bash -c 'go version; node --version; pnpm --version; pi --version'
test -f ~/.dotfiles/config/zsh/prompts/purification/prompt_purification_setup
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
zsh -i -c 'typeset -f prompt_purification_setup >/dev/null && echo ok'
# Plugins: each clone present, and each one actually loaded into the shell.
ls ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
zsh -i -c '[[ -n $widgets[fzf-tab-complete] ]] && echo fzf-tab ok'
zsh -i -c '[[ -n $widgets[fzf-history-widget] ]] && echo fzf-keybindings ok'
zsh -i -c 'typeset -f _zsh_autosuggest_start >/dev/null && echo autosuggestions ok'
zsh -i -c 'whence -w -- -fast-highlight-process >/dev/null && echo highlighting ok'
zsh -i -c 'typeset -f z >/dev/null && echo zoxide ok'
# Diff rendering.
test -L ~/.config/git/delta.gitconfig && readlink ~/.config/git/delta.gitconfig
git config --get core.pager
test -L ~/Library/Application\ Support/lazygit/config.yml
```

Windows equivalents:

```powershell
Get-Content $HOME/.dotfiles/install/platforms/windows/winget-packages.txt | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { winget list --id $_ -e --accept-source-agreements }
wsl -l -q
```

Debian equivalents:

```bash
test -L ~/.bashrc && readlink ~/.bashrc
bash -n ~/.dotfiles/config/bash/.bashrc
sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages
```

Expected:

- `mise current` resolves the Go, Node.js, Pi, and pnpm versions pinned in
  `config/mise/config.toml`; a `bash -c` launched from that shell inherits the
  same PATH and should report those versions. This does not guarantee PATH
  inheritance by GUI apps or unrelated non-shell processes.
- `uv python list --only-installed` reports uv-owned interpreters, `openai`
  resolves from Homebrew, and the PATH does not contain a version-specific
  Apple Python user-package directory.
- WSL distro exists (`wsl -l -q` non-empty) and bootstrap output includes WSL guidance. Run Debian/Ubuntu shell setup inside the WSL distro.
- The Windows bootstrap does not create native Windows shell links.
- `winget list --id ... -e` resolves each configured package.
- `FZF_DEFAULT_COMMAND` uses `fd -H -t f ...`.
- All three plugin clones exist and report ok from the interactive shell. A
  missing clone degrades the shell instead of breaking it, so check the clone
  list before concluding the config is wrong.
- `git config --get core.pager` reports `delta`, which comes from the
  `include.path` entry in `~/.gitconfig` rather than from any tracked copy of
  that file.
- Interactive Zsh defines `prompt_purification_setup` from the vendored prompt;
  it does not require `~/.config/prompt_purification`.
- Debian `~/.bashrc` links to `~/.dotfiles/config/bash/.bashrc`.
- Debian package step reports skipped when all apt manifest packages are already installed.
- Debian login shell is unchanged unless `--force-shell` was used.

Smoke-test navigation helpers in an interactive shell:

```zsh
fcd
ffcd
fview
fstack
```

## Backup

Bootstrap automatically creates collision-safe timestamped backups before
relinking regular files, directories, or incorrect symlinks. Correct symlinks
are a no-op, so converged reruns do not create additional backups:

- `~/.zshrc.bak.<timestamp>[.N]`
- `~/.zprofile.bak.<timestamp>[.N]`
- `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.bak.<timestamp>[.N]` (macOS bootstrap only, if replaced)
- `${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml.bak.<timestamp>[.N]`
  (macOS bootstrap only, if replaced)
- `${XDG_CONFIG_HOME:-$HOME/.config}/git/delta.gitconfig.bak.<timestamp>[.N]`
  (macOS bootstrap only, if replaced)
- `~/Library/Application Support/lazygit/config.yml.bak.<timestamp>[.N]`
  (macOS bootstrap only, if replaced)
- `~/.bashrc.bak.<timestamp>[.N]` (Debian bootstrap only, if replaced)

`~/.gitconfig` is edited in place rather than backed up: bootstrap only appends
one `include.path` entry with `git config --global --add`, and never rewrites
anything else in that file. Revert it with:

```zsh
git config --global --unset include.path "${XDG_CONFIG_HOME:-$HOME/.config}/git/delta.gitconfig"
```

You can additionally snapshot the repo:

```zsh
cd ~/.dotfiles
git tag backup-$(date +%Y%m%d-%H%M%S)
```

## Restore

1. Remove current managed symlink.
2. Move chosen `*.bak.<timestamp>[.N]` back to original path.
3. Start a new shell.

Example—remove the current path only when it is the expected repo-owned link:

```zsh
expected="$HOME/.dotfiles/config/zsh/.zshrc"
if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$expected" ]]; then
  rm -- "$HOME/.zshrc"
  mv ~/.zshrc.bak.20260224010101 ~/.zshrc
  exec zsh
else
  echo "Refusing to remove ~/.zshrc: it is not the expected managed link" >&2
fi
```

Debian bash example:

```bash
expected="$HOME/.dotfiles/config/bash/.bashrc"
if [ -L "$HOME/.bashrc" ] && [ "$(readlink "$HOME/.bashrc")" = "$expected" ]; then
  rm -- "$HOME/.bashrc"
  mv ~/.bashrc.bak.20260224010101 ~/.bashrc
  exec bash
else
  echo "Refusing to remove ~/.bashrc: it is not the expected managed link" >&2
fi
```

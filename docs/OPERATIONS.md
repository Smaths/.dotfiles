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
- `--yes`: run without interactive confirmation.
- `--verbose`: show extra command detail.
- `--upgrade-packages` (macOS only): upgrade outdated Brewfile entries during
  bootstrap.
- `--skip-packages` (Windows only): skip `winget` installs.
- `--link-windows-shell` (Windows only): also link Windows `~/.zshrc` and `~/.zprofile` (default is WSL-first skip).
- `--skip-packages` (Debian only): skip `apt-get` installs.
- `--force-shell` (Debian only): change the current user's login shell to bash.

Interactive Unix runs print a preflight plan and ask for confirmation before
installing packages or relinking config. Non-TTY mutation requires `--yes`;
otherwise use `--dry-run` to inspect the plan.

macOS settings are separate from bootstrap. Run them explicitly when wanted:

```zsh
zsh ~/.dotfiles/install/platforms/macos/settings.zsh
```

The settings script offers three modes:

- `1) Use defaults (no per-setting prompts)`: applies repo defaults after confirmation.
- `2) Choose settings`: set defaults for each setting, then proceed.
- `3) Skip`: exits macOS tuning without applying defaults.

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
install or verify the pinned Node.js, Pi, and pnpm versions. Because the config
sits at the path mise reads by default, no environment variable is needed and
every process resolves the same tools. Node.js 24 and pnpm 11 are the defaults;
Node.js 22.12.0 is also installed for projects that select it through `.nvmrc`
or `.node-version`, and Pi 0.82.1 provides the `pi` terminal agent. A project's
`packageManager` field remains the source of truth for selecting another pnpm
version through mise.

Bootstrap also symlinks `config/uv/uv.toml` to
`${XDG_CONFIG_HOME:-~/.config}/uv/uv.toml`. uv uses only uv-managed Python
interpreters for projects and Python-package tools; Apple/Xcode Python and its
user package directory are not modified or added to `PATH`. Standalone native
applications such as the official OpenAI CLI are installed through Homebrew.

To intentionally upgrade outdated Homebrew packages and casks during bootstrap:

```zsh
sh install/bootstrap.sh --upgrade-packages
```

For unattended maintenance, pass `--yes` explicitly:

```zsh
sh install/bootstrap.sh --yes
```

Node.js, Pi, and pnpm upgrades are intentional config changes rather than side
effects of a Homebrew upgrade. Update the defaults and any required Node.js
compatibility runtimes, review the diff, then rerun bootstrap. Keep project
runtime and package-manager pins until their projects are tested on newer
versions.

```zsh
${EDITOR:-vi} ~/.dotfiles/config/mise/config.toml
mise install
sh install/bootstrap.sh
```

Check the versions selected in a project directory before installing
dependencies:

```zsh
mise current
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
node --version
pnpm --version
pi --version
test -L ~/.config/uv/uv.toml && readlink ~/.config/uv/uv.toml
uv python list --only-installed
openai --version
# Apple/Xcode Python remains available, but its user scripts are not global.
/usr/bin/python3 --version
zsh -lc '[[ ":$PATH:" != *":$HOME/Library/Python/3.9/bin:"* ]]'
# Same tools outside zsh: this is what scripts, editors, and hooks see.
bash -c 'node --version; pnpm --version; pi --version'
test -f ~/.dotfiles/config/zsh/prompts/purification/prompt_purification_setup
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
zsh -i -c 'typeset -f prompt_purification_setup >/dev/null && echo ok'
```

Windows equivalents:

```powershell
Get-Item $HOME/.zshrc | Select-Object FullName, LinkType, Target
Get-Item $HOME/.zprofile | Select-Object FullName, LinkType, Target
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

- `mise current` resolves the Node.js, Pi, and pnpm versions pinned in
  `config/mise/config.toml`, and reports the same versions under `bash -c`. A
  mismatch between the two means the mise config symlink is missing.
- `uv python list --only-installed` reports uv-owned interpreters, `openai`
  resolves from Homebrew, and the PATH does not contain a version-specific
  Apple Python user-package directory.
- WSL distro exists (`wsl -l -q` non-empty) and bootstrap output includes the WSL shell/tmux setup commands.
- Windows `~/.zshrc` and `~/.zprofile` are linked only if `--link-windows-shell` was used.
- `winget list --id ... -e` resolves each configured package.
- `FZF_DEFAULT_COMMAND` uses `fd -H -t f ...`.
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
- `~/.bashrc.bak.<timestamp>[.N]` (Debian bootstrap only, if replaced)

You can additionally snapshot the repo:

```zsh
cd ~/.dotfiles
git tag backup-$(date +%Y%m%d-%H%M%S)
```

## Restore

1. Remove current managed symlink.
2. Move chosen `*.bak.<timestamp>[.N]` back to original path.
3. Start a new shell.

Example:

```zsh
rm -f ~/.zshrc
mv ~/.zshrc.bak.20260224010101 ~/.zshrc
exec zsh
```

Debian bash example:

```bash
rm -f ~/.bashrc
mv ~/.bashrc.bak.20260224010101 ~/.bashrc
exec bash
```

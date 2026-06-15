# Operations

## Install (Fresh Machine)

```zsh
git clone <repo-url> ~/.dotfiles
zsh ~/.dotfiles/install/bootstrap.zsh
```

Windows:

```powershell
git clone <repo-url> $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap-windows.ps1
```

Debian server:

```bash
git clone <repo-url> ~/.dotfiles
bash ~/.dotfiles/install/bootstrap-debian.sh
```

Useful flags:

- `--dry-run`: print intended actions without mutating.
- `--verbose`: show extra command detail.
- `--skip-macos`: skip interactive defaults prompts.
- `--upgrade-packages` (macOS only): upgrade outdated Brewfile entries during bootstrap.
- `--skip-packages` (Windows only): skip `winget` installs.
- `--link-windows-shell` (Windows only): also link Windows `~/.zshrc` and `~/.zprofile` (default is WSL-first skip).
- `--skip-packages` (Debian only): skip `apt-get` installs.
- `--force-shell` (Debian only): change the current user's login shell to bash.

During `install/macos.zsh`, choose one startup mode before the setting prompts:

- `1) Use defaults (no per-setting prompts)`: applies repo defaults after confirmation.
- `2) Choose settings`: set defaults for each setting, then proceed.
- `3) Skip`: exits macOS tuning without applying defaults.

## Update (Existing Machine)

```zsh
cd ~/.dotfiles
git pull --ff-only
zsh install/bootstrap.zsh --skip-macos
```

The macOS bootstrap checks the Brewfile first and skips `brew bundle install`
when all entries are already present. When installation is needed, it uses
`brew bundle install --no-upgrade --jobs=auto` so reruns install missing entries
without turning every bootstrap into a full Homebrew upgrade pass.

To intentionally upgrade outdated Homebrew packages and casks during bootstrap:

```zsh
zsh install/bootstrap.zsh --skip-macos --upgrade-packages
```

Windows update flow:

```powershell
Set-Location $HOME/.dotfiles
git pull --ff-only
powershell -ExecutionPolicy Bypass -File install/bootstrap-windows.ps1 --skip-packages
```

Debian update flow:

```bash
cd ~/.dotfiles
git pull --ff-only
bash install/bootstrap-debian.sh --skip-packages
```

Re-enable interactive defaults only when needed:

```zsh
zsh install/bootstrap.zsh
```

## Doctor (Health Checks)

Manual checks:

```zsh
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
brew bundle check --file ~/.dotfiles/install/Brewfile
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
```

Windows equivalents:

```powershell
Get-Item $HOME/.zshrc | Select-Object FullName, LinkType, Target
Get-Item $HOME/.zprofile | Select-Object FullName, LinkType, Target
Get-Content $HOME/.dotfiles/install/winget-packages.txt | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { winget list --id $_ -e --accept-source-agreements }
wsl -l -q
```

Debian equivalents:

```bash
test -L ~/.bashrc && readlink ~/.bashrc
bash -n ~/.dotfiles/config/bash/.bashrc
bash ~/.dotfiles/install/bootstrap-debian.sh --dry-run --skip-packages
```

Expected:

- WSL distro exists (`wsl -l -q` non-empty) and bootstrap output includes the WSL shell/tmux setup commands.
- Windows `~/.zshrc` and `~/.zprofile` are linked only if `--link-windows-shell` was used.
- `winget list --id ... -e` resolves each configured package.
- `FZF_DEFAULT_COMMAND` uses `fd -H -t f ...`.
- Debian `~/.bashrc` links to `~/.dotfiles/config/bash/.bashrc`.
- Debian login shell is unchanged unless `--force-shell` was used.

Smoke-test navigation helpers in an interactive shell:

```zsh
fcd
ffcd
fview
fstack
```

## Backup

Bootstrap automatically creates timestamped backups before relinking:

- `~/.zshrc.bak.<timestamp>`
- `~/.zprofile.bak.<timestamp>`
- `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.bak.<timestamp>` (macOS bootstrap only, if replaced)
- `~/.bashrc.bak.<timestamp>` (Debian bootstrap only, if replaced)

You can additionally snapshot the repo:

```zsh
cd ~/.dotfiles
git tag backup-$(date +%Y%m%d-%H%M%S)
```

## Restore

1. Remove current managed symlink.
2. Move chosen `*.bak.<timestamp>` back to original path.
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

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

Useful flags:

- `--dry-run`: print intended actions without mutating.
- `--verbose`: show extra command detail.
- `--skip-macos`: skip interactive defaults prompts.
- `--skip-packages` (Windows only): skip `winget` installs.

## Update (Existing Machine)

```zsh
cd ~/.dotfiles
git pull --ff-only
zsh install/bootstrap.zsh --skip-macos
```

Windows update flow:

```powershell
Set-Location $HOME/.dotfiles
git pull --ff-only
powershell -ExecutionPolicy Bypass -File install/bootstrap-windows.ps1 --skip-packages
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
brew bundle check --file ~/.dotfiles/brew/Brewfile
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
```

Windows equivalents:

```powershell
Get-Item $HOME/.zshrc | Select-Object FullName, LinkType, Target
Get-Item $HOME/.zprofile | Select-Object FullName, LinkType, Target
Get-Content $HOME/.dotfiles/install/winget-packages.txt | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { winget list --id $_ -e --accept-source-agreements }
```

Expected:

- `~/.zshrc` and `~/.zprofile` point to this repo.
- `winget list --id ... -e` resolves each configured package.
- `FZF_DEFAULT_COMMAND` uses `rg --files ...`.

## Backup

Bootstrap automatically creates timestamped backups before relinking:

- `~/.zshrc.bak.<timestamp>`
- `~/.zprofile.bak.<timestamp>`
- `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.bak.<timestamp>` (macOS bootstrap only, if replaced)

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

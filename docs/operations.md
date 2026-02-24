# Operations

## Install (Fresh Machine)

```zsh
git clone <repo-url> ~/.dotfiles
zsh ~/.dotfiles/install/bootstrap.zsh
```

Useful flags:

- `--dry-run`: print intended actions without mutating.
- `--verbose`: show extra command detail.
- `--skip-macos`: skip interactive defaults prompts.

## Update (Existing Machine)

```zsh
cd ~/.dotfiles
git pull --ff-only
zsh install/bootstrap.zsh --skip-macos
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

Expected:

- `~/.zshrc` and `~/.zprofile` point to this repo.
- `brew bundle check` exits clean.
- `FZF_DEFAULT_COMMAND` uses `rg --files ...`.

## Backup

Bootstrap automatically creates timestamped backups before relinking:

- `~/.zshrc.bak.<timestamp>`
- `~/.zprofile.bak.<timestamp>`
- `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.bak.<timestamp>` (if replaced)

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

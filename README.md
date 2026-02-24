# Dotfiles

![Bootstrap Screenshot](assets/screenshot_1.png)

macOS dotfiles for fast, repeatable snarfum machine setup.

## What This Does

- Installs Homebrew (if missing) and packages/apps from `brew/Brewfile`
- Ensures `git` is available
- Installs `fzf` + `ripgrep` and configures `fzf` to source files via `rg`
- Symlinks shell configs:
  - `~/.zshrc` -> `~/.dotfiles/config/zsh/.zshrc`
  - `~/.zprofile` -> `~/.dotfiles/config/zsh/.zprofile`
- Symlinks Ghostty config using XDG path:
  - `$XDG_CONFIG_HOME/ghostty/config` (fallback: `~/.config/ghostty/config`)
- Optionally runs interactive macOS tweaks via `install/macos.zsh`

## Run

```zsh
zsh ~/.dotfiles/install/bootstrap.zsh
```

## Common Flags

```zsh
zsh ~/.dotfiles/install/bootstrap.zsh --dry-run
zsh ~/.dotfiles/install/bootstrap.zsh --verbose
zsh ~/.dotfiles/install/bootstrap.zsh --skip-macos
```

## Notes

- Safe to rerun: existing files are backed up before relinking.
- Brew steps run quietly with periodic progress peeks.
- On brew failure, recent logs are shown and full log path is printed.

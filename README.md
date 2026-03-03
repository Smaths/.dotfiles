# Dotfiles

![Bootstrap Screenshot](docs/assets/screenshot_1.png)

Personal dotfiles for reproducible shell and workstation setup, centered on macOS with a Windows bootstrap entrypoint.

## Purpose

This repo bootstraps a machine with packages, shell config, and a small set of app
configs while preserving existing user files via timestamped backups.

## Supported Platforms

- **Primary**: macOS 13+ (Homebrew-based bootstrap).
- **Secondary**: Windows (WSL-first) via `install/bootstrap-windows.ps1`.
- **Unsupported**: Linux for config reuse only; no Linux bootstrap entrypoint.

See [Platform Notes](docs/platforms.md) for details and prerequisites.

## Quick Install

macOS

```zsh
git clone <repo-url> ~/.dotfiles
zsh ~/.dotfiles/install/bootstrap.zsh
```

Windows (PowerShell): Note the ByPass command, review code before executing.

```powershell
git clone <repo-url> $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap-windows.ps1
```

> [!WARNING]
> Review and understand the bootstrap scripts before execution. The dotfiles repo will modify shell configuration files and install packages. Ensure backups exist and you have rollback understanding (see [Rollback / Uninstall](#rollback--uninstall)).

Linux:

- No Linux bootstrap script currently.
- Reuse config modules under `config/zsh/` manually.

### Flags

Global:

```zsh
zsh --dry-run
zsh --verbose
```

macOS-only:

```zsh
zsh --skip-macos
```

Windows-only:

```powershell
--skip-packages
--link-windows-shell
```

## Safe Defaults

- Cross-platform:
  - Idempotent intent: reruns should be safe and mostly no-op when already configured.
  - Before relinking `~/.zshrc` or `~/.zprofile`, existing files are moved to
    timestamped backups (`.bak.YYYYmmddHHMMSS`).
- macOS:
  - `install/macos.zsh` is interactive and opt-out via `--skip-macos`.
  - macOS setup prompt modes:
    - use defaults (no per-setting prompts)
    - choose settings (set defaults, then proceed)
    - skip
- Windows:
  - Validates `winget` package IDs before installation.
  - Checks symlink capability only when `--link-windows-shell` is requested.
- Shell config:
  - `fzf` defaults are wired to `fd` (`FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`)
    with hidden files included and shared excludes for heavy paths (for example:
    `.git`, `node_modules`, `.cache`, `dist`, `build`, `.next`, `.turbo`,
    `coverage`, `target`).

## Features

### Fuzzy Navigation Helpers

- `fcd [root]`: fuzzy-select a directory and change into it.
- `ffcd [root]`: fuzzy-select a file and change into that file's directory.
- `fview [root]`: fuzzy-select a file and view it in-terminal (`bat`/`less`).
- `fstack`: fuzzy-select a `dirs -v` stack entry and jump to it.

## What Gets Managed

- Shared:
  - Symlink targets:
    - `~/.zshrc` -> `~/.dotfiles/config/zsh/.zshrc`
    - `~/.zprofile` -> `~/.dotfiles/config/zsh/.zprofile`
  - Zsh module chain via `config/zsh/.zshrc` -> `config/zsh/*.zsh`.
- macOS:
  - Homebrew packages and casks from `install/Brewfile` (includes `fd`, `fzf`, and `ripgrep`).
  - Ghostty symlink:
    - `$XDG_CONFIG_HOME/ghostty/config` -> `~/.dotfiles/config/ghostty/config`
  - Optional interactive system defaults in `install/macos.zsh`.
- Windows:
  - Packages from `install/winget-packages.txt` via `winget` (when available).
  - WSL-first guidance output (installs/linking commands for WSL shell environment).
  - Windows-host zsh linking only when `--link-windows-shell` is passed.
- Linux:
  - No package/bootstrap automation managed today.

## Rollback / Uninstall

1. Remove symlinks if present.
2. Restore backups created by bootstrap (`*.bak.<timestamp>`) as needed.
3. Optionally uninstall managed packages.
4. Remove the repo clone.

macOS cleanup commands:

```zsh
rm -f ~/.zshrc ~/.zprofile
rm -f ${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config
brew bundle cleanup --file ~/.dotfiles/install/Brewfile --force
rm -rf ~/.dotfiles
```

Windows cleanup commands:

```powershell
Remove-Item $HOME\.zshrc,$HOME\.zprofile -Force -ErrorAction SilentlyContinue
# Then remove package installs manually or via winget uninstall as needed.
Remove-Item $HOME\.dotfiles -Recurse -Force
```

Linux cleanup:

- Remove any manual symlinks you created.
- Remove repo clone.

## Entry Points

- macOS bootstrap: `install/bootstrap.zsh`
- Windows bootstrap: `install/bootstrap-windows.ps1`
- macOS tuning (optional): `install/macos.zsh`
- macOS package manifest: `install/Brewfile`
- Windows package manifest: `install/winget-packages.txt`
- Shell entrypoint chain: `config/zsh/.zshrc` -> `config/zsh/*.zsh`

## Validation Commands

Run after changing install/config behavior:

```zsh
shellcheck install/*.zsh config/zsh/*.zsh
shfmt -w -i 2 -ci install/*.zsh config/zsh/*.zsh
brew bundle check --file ~/.dotfiles/install/Brewfile
```

Windows package manifest check:

```powershell
Get-Content $HOME/.dotfiles/install/winget-packages.txt | `
  Where-Object { $_ -and -not $_.StartsWith('#') } | `
  ForEach-Object { winget search --id $_ -e }
```

If available:

- `dot doctor`

## Off-Limits and Invariants

- Scripts should not delete user files by default.
- No secret material (tokens/keys/passwords) should be committed.
- Network installs are limited to explicit bootstrap dependencies (`brew`, `winget`, `git`, `curl`).

See:

- [Architecture](docs/ARCHITECTURE.md)
- [Platform Notes](docs/platforms.md)
- [Operations](docs/operations.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

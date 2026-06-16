# Dotfiles

![Bootstrap Screenshot](docs/assets/screenshot_1.png)

Personal dotfiles for reproducible shell and workstation setup, centered on macOS with secondary Windows and Debian server bootstrap entrypoints.

## Purpose

This repo bootstraps a machine with packages, shell config, and a small set of app
configs while preserving existing user files via timestamped backups.

## Supported Platforms

- **Primary**: macOS 13+ (Homebrew-based bootstrap via `install/bootstrap.sh`).
- **Secondary**: Windows (WSL-first) via `install/bootstrap.ps1`.
- **Secondary**: Debian server via `install/bootstrap.sh`.
- **Unsupported**: Other Linux distributions for config reuse only; no generic Linux bootstrap entrypoint.

See [Platform Notes](docs/platforms.md) for details and prerequisites.

## Quick Install

macOS

```zsh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

Windows (PowerShell): Note the Bypass command, review code before executing.

```powershell
git clone https://github.com/Smaths/.dotfiles.git $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap.ps1
```

Debian server:

```bash
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

> [!WARNING]
> Review and understand the bootstrap scripts before execution. The dotfiles repo will modify shell configuration files and install packages. Ensure backups exist and you have rollback understanding (see [Rollback / Uninstall](#rollback--uninstall)).

Linux:

- Debian servers are supported through `install/bootstrap.sh`, which dispatches to `install/platforms/debian/bootstrap.sh`.
- Other Linux distributions can reuse config modules manually.

### Flags

Global:

```zsh
sh install/bootstrap.sh --dry-run
sh install/bootstrap.sh --verbose
```

macOS-only:

```zsh
zsh --skip-macos
zsh --upgrade-packages
```

Windows-only:

```powershell
--skip-packages
--link-windows-shell
```

Debian-only:

```bash
--skip-packages
--force-shell
```

## Safe Defaults

- Cross-platform:
  - Idempotent intent: reruns should be safe and mostly no-op when already configured.
  - Before relinking `~/.zshrc` or `~/.zprofile`, existing files are moved to
    timestamped backups (`.bak.YYYYmmddHHMMSS`).
- macOS:
  - `install/platforms/macos/settings.zsh` is interactive and opt-out via `--skip-macos`.
  - Homebrew package upgrades require explicit `--upgrade-packages` opt-in.
  - macOS setup prompt modes:
    - use defaults (no per-setting prompts)
    - choose settings (set defaults, then proceed)
    - skip
- Windows:
  - Validates `winget` package IDs before installation.
  - Checks symlink capability only when `--link-windows-shell` is requested.
- Debian:
  - Uses apt packages from `install/platforms/debian/apt-packages.txt`.
  - Links `~/.bashrc` to `config/bash/.bashrc` with timestamped backup behavior.
  - Leaves the login shell unchanged unless `--force-shell` is passed.
- Shell config:
  - `fzf` defaults are wired to `fd` (`FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`)
    with hidden files included and shared excludes for heavy paths (for example:
    `.git`, `node_modules`, `.cache`, `dist`, `build`, `.next`, `.turbo`,
    `coverage`, `target`).
  - 1Password SSH agent routing is configured in `config/zsh/env.zsh` via `SSH_AUTH_SOCK` when the socket exists; keep app-injected shell snippets in `config/zsh/local.zsh` instead of tracked entrypoints.
  - Alias modules load from `config/zsh/aliases/*.zsh` in lexical order; keep project/machine-specific overrides in `config/zsh/local.zsh`.

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
  - Homebrew packages and casks from `install/platforms/macos/Brewfile` (includes `fd`, `fzf`, and `ripgrep`).
  - Bootstrap installs missing Brewfile entries without upgrading existing packages by default; pass `--upgrade-packages` to upgrade outdated entries.
  - Ghostty symlink:
    - `$XDG_CONFIG_HOME/ghostty/config` -> `~/.dotfiles/config/ghostty/config`
  - Optional interactive system defaults in `install/platforms/macos/settings.zsh`.
- Windows:
  - Packages from `install/platforms/windows/winget-packages.txt` via `winget` (when available).
  - WSL-first guidance output (installs/linking commands for WSL shell environment).
  - Windows-host zsh linking only when `--link-windows-shell` is passed.
- Debian:
  - Packages from `install/platforms/debian/apt-packages.txt` via `apt-get`.
  - Bash symlink:
    - `~/.bashrc` -> `~/.dotfiles/config/bash/.bashrc`
  - Optional login shell update to bash via `--force-shell`.

## Rollback / Uninstall

1. Remove symlinks if present.
2. Restore backups created by bootstrap (`*.bak.<timestamp>`) as needed.
3. Optionally uninstall managed packages.
4. Remove the repo clone.

macOS cleanup commands:

```zsh
rm -f ~/.zshrc ~/.zprofile
rm -f ${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config
brew bundle cleanup --file ~/.dotfiles/install/platforms/macos/Brewfile --force
rm -rf ~/.dotfiles
```

Windows cleanup commands:

```powershell
Remove-Item $HOME\.zshrc,$HOME\.zprofile -Force -ErrorAction SilentlyContinue
# Then remove package installs manually or via winget uninstall as needed.
Remove-Item $HOME\.dotfiles -Recurse -Force
```

Debian cleanup:

```bash
rm -f ~/.bashrc
# Restore ~/.bashrc.bak.<timestamp> if needed.
rm -rf ~/.dotfiles
```

Other Linux cleanup:

- Remove any manual symlinks you created.
- Remove the repo clone.

## Entry Points

- Unix bootstrap wrapper: `install/bootstrap.sh`
- Windows bootstrap wrapper: `install/bootstrap.ps1`
- macOS bootstrap: `install/platforms/macos/bootstrap.zsh`
- Windows bootstrap: `install/platforms/windows/bootstrap.ps1`
- Debian bootstrap: `install/platforms/debian/bootstrap.sh`
- macOS settings (optional): `install/platforms/macos/settings.zsh`
- Shared Unix bootstrap UI: `install/lib/ui.sh`
- macOS package manifest: `install/platforms/macos/Brewfile`
- Windows package manifest: `install/platforms/windows/winget-packages.txt`
- Debian package manifest: `install/platforms/debian/apt-packages.txt`
- Shell entrypoint chain: `config/zsh/.zshrc` -> `config/zsh/*.zsh`
- Debian bash entrypoint: `config/bash/.bashrc`

## Validation Commands

Run after changing install/config behavior:

```zsh
shellcheck install/*.sh install/lib/*.sh install/platforms/*/*.sh install/platforms/*/*.zsh config/zsh/*.zsh config/bash/*.bash config/bash/.bashrc
shfmt -w -i 2 -ci install/platforms/*/*.zsh config/zsh/*.zsh
sh -n install/bootstrap.sh
sh -n install/lib/ui.sh
bash -n install/platforms/debian/bootstrap.sh config/bash/.bashrc
brew bundle check --file ~/.dotfiles/install/platforms/macos/Brewfile
```

Debian dry-run check:

```bash
sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages
```

Windows package manifest check:

```powershell
Get-Content $HOME/.dotfiles/install/platforms/windows/winget-packages.txt | `
  Where-Object { $_ -and -not $_.StartsWith('#') } | `
  ForEach-Object { winget search --id $_ -e }
```

If available:

- `dot doctor`

## Off-Limits and Invariants

- Scripts should not delete user files by default.
- No secret material (tokens/keys/passwords) should be committed.
- Network installs are limited to explicit bootstrap dependencies (`brew`, `winget`, `apt-get`, `git`, `curl`).

See:

- [Architecture](docs/ARCHITECTURE.md)
- [Platform Notes](docs/platforms.md)
- [Operations](docs/OPERATIONS.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

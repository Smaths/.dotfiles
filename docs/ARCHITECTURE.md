# Architecture

## Overview

This repo defines a small, explicit mapping from tracked files to paths in `$HOME`.
The design goal is predictable bootstrap behavior with minimal surprise.

## File-to-Home Mapping

- `config/zsh/.zshrc` -> `~/.zshrc` (symlink)
- `config/zsh/.zprofile` -> `~/.zprofile` (symlink)
- `config/bash/.bashrc` -> `~/.bashrc` (symlink on Debian)
- `config/ghostty/config` -> `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config` (symlink)
- `config/tmux/tmux.conf` -> `~/.tmux.conf` (symlink on macOS and Debian)
- `install/Brewfile` is consumed by macOS bootstrap via `brew bundle`.
- `install/winget-packages.txt` is consumed by Windows bootstrap via `winget install`.
- `install/apt-packages.txt` is consumed by Debian bootstrap via `apt-get install` after checking for missing packages.
- Windows bootstrap is WSL-first: it provides WSL shell setup commands by default and only links Windows shell files when `--link-windows-shell` is passed.

Other files under `config/zsh/*.zsh` are sourced by `config/zsh/.zshrc`.

`config/bash/.bashrc` is intentionally standalone for Debian servers. It mirrors
only portable shell defaults and small aliases instead of sourcing zsh modules.

## Zsh Module Boundaries

- `config/zsh/options.zsh`: shell options, history behavior, and directory-stack options.
- `config/zsh/path.zsh`: `PATH` and path-like variable setup.
- `config/zsh/env.zsh`: exported environment variables, including `FZF_*` defaults.
- `config/zsh/completion.zsh`: completion system configuration.
- `config/zsh/plugins.zsh`: plugin/keybinding sourcing only (for example `~/.fzf.zsh`).
- `config/zsh/functions/*.zsh`: interactive helper functions (for example `fcd`, `ffcd`, `fview`, `fstack`).
- `config/zsh/aliases.zsh`: aliases and short shell convenience commands.

## Symlink Strategy

`install/bootstrap-macos.zsh` uses `link_with_backup()`:

- If the link already targets the expected file, no change.
- If a non-link file exists, it is moved to `*.bak.<timestamp>`.
- Then `ln -sfn` creates/updates the symlink.

This preserves user state and enables safe reruns.

`install/bootstrap-debian.sh` uses the same backup-before-symlink strategy for
`~/.bashrc`.

## Ownership and Scope

- Managed by this repo:
  - symlink targets listed above
  - package sets in `install/Brewfile` and `install/winget-packages.txt`
  - Debian package set in `install/apt-packages.txt`
- Not managed by this repo:
  - user secrets, keychains, tokens
  - arbitrary files in `$HOME` not explicitly linked
  - package managers outside `brew`, `winget`, and `apt-get`

## Idempotency Goals

- Running bootstrap repeatedly should converge to one valid state.
- Existing valid symlinks should remain unchanged.
- Re-run noise should be minimal; destructive operations require explicit opt-in.

## Invariants

- Bootstrap wrappers are thin dispatchers (`install/bootstrap.sh` for macOS/Debian, `install/bootstrap.ps1` for Windows).
- Platform bootstrap scripts stay explicit (`install/bootstrap-macos.zsh`, `install/bootstrap-windows.ps1`, `install/bootstrap-debian.sh`).
- Required package manifest and symlink targets must exist before mutation.
- `install/macos.zsh` is interactive and optional via `--skip-macos`.
- Debian package installation skips `apt-get update` and `apt-get install` when the apt manifest is already satisfied.
- Debian login shell changes require explicit `--force-shell`.

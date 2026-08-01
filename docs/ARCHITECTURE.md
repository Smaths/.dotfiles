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
- `config/mise/config.toml` -> `${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml`
  (symlink on macOS). It declares the default Node.js and pnpm toolchain plus a
  Node.js compatibility runtime; project `.nvmrc`, `.node-version`, and
  `packageManager` metadata can override the active versions. Linking it to the
  path mise already reads by default means every process resolves the same
  toolchain, rather than only shells that source `config/zsh/env.zsh`.
- `install/platforms/macos/Brewfile` is consumed by macOS bootstrap via `brew bundle`.
- `install/platforms/windows/winget-packages.txt` is consumed by Windows bootstrap via `winget install`.
- `install/platforms/debian/apt-packages.txt` is consumed by Debian bootstrap via `apt-get install` after checking for missing packages.
- Windows bootstrap is WSL-first: it provides WSL shell setup commands by default and only links Windows shell files when `--link-windows-shell` is passed.

Other files under `config/zsh/*.zsh` are sourced by `config/zsh/.zshrc`.

`config/bash/.bashrc` is intentionally standalone for Debian servers. It mirrors
only portable shell defaults and small aliases instead of sourcing zsh modules.

## Zsh Module Boundaries

- `config/zsh/options.zsh`: shell options, history behavior, and directory-stack options.
- `config/zsh/path.zsh`: `PATH` and path-like variable setup, including the mise
  shims directory. Shims are the only mise activation mechanism; `mise activate`
  is deliberately not used, because shims also cover non-interactive and non-zsh
  processes and running both mechanisms is unsupported.
- `config/zsh/env.zsh`: exported environment variables, including `FZF_*`
  defaults.
- `config/zsh/completion.zsh`: completion system configuration.
- `config/zsh/plugins.zsh`: plugin/keybinding sourcing only (for example `~/.fzf.zsh`).
- `config/zsh/functions/*.zsh`: interactive helper functions (for example `fcd`, `ffcd`, `fview`, `fstack`).
- `config/zsh/aliases.zsh`: aliases and short shell convenience commands.

## Symlink Strategy

`install/lib/common.sh` provides `link_with_backup()` to both the macOS and
Debian bootstraps:

- If the link already targets the expected file, no change.
- If another file, directory, or symlink exists, it is moved once to a
  collision-safe `*.bak.<timestamp>[.N]` path.
- Then `ln -s` creates the canonical symlink.

This preserves user state without generating additional backups on converged
reruns.

The shared library also owns dry-run command execution, required-command checks,
and collision-safe backup path selection. Its callers define `DRY_RUN` and
`VERBOSE`; package operations, preflight plans, and root escalation remain
platform-specific.

`install/lib/ui.sh` provides shared Unix bootstrap presentation helpers for
headers, aligned step output, status marks, and summary rendering.

## Ownership and Scope

- Managed by this repo:
  - symlink targets listed above
  - package sets under `install/platforms/*/`
  - Node.js and pnpm versions declared in `config/mise/config.toml`
- Not managed by this repo:
  - user secrets, keychains, tokens
  - arbitrary files in `$HOME` not explicitly linked
  - package managers outside `brew`, `mise`, `winget`, and `apt-get`

## Idempotency Goals

- Running bootstrap repeatedly should converge to one valid state.
- Existing valid symlinks should remain unchanged.
- Re-run noise should be minimal; destructive operations require explicit opt-in.

## Invariants

- Bootstrap wrappers are thin dispatchers (`install/bootstrap.sh` for macOS/Debian, `install/bootstrap.ps1` for Windows).
- Platform bootstrap scripts stay explicit under `install/platforms/{macos,windows,debian}/`.
- Shared bootstrap behavior and UI helpers live under `install/lib/`.
- Required package manifest and symlink targets must exist before mutation.
- `install/platforms/macos/settings.zsh` is interactive, standalone, and never
  invoked by bootstrap.
- Debian package installation skips `apt-get update` and `apt-get install` when the apt manifest is already satisfied.
- Debian login shell changes require explicit `--force-shell`.

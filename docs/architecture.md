# Architecture

## Overview

This repo defines a small, explicit mapping from tracked files to paths in `$HOME`.
The design goal is predictable bootstrap behavior with minimal surprise.

## File-to-Home Mapping

- `config/zsh/.zshrc` -> `~/.zshrc` (symlink)
- `config/zsh/.zprofile` -> `~/.zprofile` (symlink)
- `config/ghostty/config` -> `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config` (symlink)
- `brew/Brewfile` is consumed by `brew bundle` during bootstrap.

Other files under `config/zsh/*.zsh` are sourced by `config/zsh/.zshrc`.

## Symlink Strategy

`install/bootstrap.zsh` uses `link_with_backup()`:

- If the link already targets the expected file, no change.
- If a non-link file exists, it is moved to `*.bak.<timestamp>`.
- Then `ln -sfn` creates/updates the symlink.

This preserves user state and enables safe reruns.

## Ownership and Scope

- Managed by this repo:
  - symlink targets listed above
  - package set in `brew/Brewfile`
- Not managed by this repo:
  - user secrets, keychains, tokens
  - arbitrary files in `$HOME` not explicitly linked
  - non-Homebrew package managers

## Idempotency Goals

- Running bootstrap repeatedly should converge to one valid state.
- Existing valid symlinks should remain unchanged.
- Re-run noise should be minimal; destructive operations require explicit opt-in.

## Invariants

- Bootstrap is macOS-only (`Darwin` check).
- `brew/Brewfile` and symlink targets must exist before mutation.
- `install/macos.zsh` is interactive and optional via `--skip-macos`.

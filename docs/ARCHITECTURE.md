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
  (symlink on macOS). It declares the default Go, Node.js, and pnpm toolchain
  plus the Pi terminal agent; project mise configs, `.nvmrc`, `.node-version`,
  and `packageManager` metadata can override the active versions. Linking it to
  the path mise reads by default avoids environment-variable selection drift.
  The managed Zsh login PATH adds the mise shims; GUI and arbitrary non-shell
  processes do not necessarily inherit that PATH.
- `config/uv/uv.toml` -> `${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml`
  (symlink on macOS). It confines uv operations to uv-managed Python
  interpreters instead of Apple/Xcode or Homebrew Python.
- `config/git/delta.gitconfig` ->
  `${XDG_CONFIG_HOME:-$HOME/.config}/git/delta.gitconfig` (symlink on macOS),
  plus one `include.path` entry appended to `~/.gitconfig`. That include is the
  only write this repo makes to a file it does not own: `~/.gitconfig` holds
  per-machine identity, signing, and credential settings, so it stays untracked.
- `config/lazygit/config.yml` -> lazygit's config directory
  (`lazygit --print-config-dir`; `~/Library/Application Support/lazygit` on
  macOS). lazygit does not read git's `core.pager`, so delta is configured for
  it separately. lazygit rewrites this file in place when migrating its own
  config schema, which surfaces as a working-tree change in this repo.
- `install/platforms/macos/Brewfile` is the core development/workstation
  manifest consumed by macOS bootstrap via `brew bundle`.
- `install/platforms/macos/Brewfile.creative` is the sole optional specialist
  creative/audio manifest. macOS bootstrap consumes it only with `--creative`.
  Ableton Live is left to its vendor installer; the manifest owns Unity Hub,
  while exact Unity editor versions follow each project's
  `ProjectSettings/ProjectVersion.txt` through Hub or the Unity CLI.
- `install/platforms/windows/winget-packages.txt` is consumed by Windows bootstrap via `winget install`.
- `install/platforms/debian/apt-packages.txt` is consumed by Debian bootstrap via `apt-get install` after checking for missing packages.
- Windows bootstrap manages host applications through winget and provides WSL setup guidance. It never links native Windows shell files; Debian/Ubuntu WSL uses the Debian Bash/tmux bootstrap.

`config/zsh/.zprofile` runs `brew shellenv` and then sources
`config/zsh/path.zsh`, once, for login shells. That order is load-bearing:
`brew shellenv` prepends the Homebrew prefix to `PATH`, so running it after
`path.zsh` would place Homebrew's runtimes ahead of the mise shims and defeat
per-project version resolution. Interactive shells inherit the resulting `PATH`; this does not imply that GUI
or arbitrary non-shell processes inherit it. Remaining tracked shared modules
under `config/zsh/*.zsh` are sourced by `config/zsh/.zshrc`.
`config/zsh/options.zsh` adds the tracked
`config/zsh/prompts/purification/` directory to `fpath` and initializes the
vendored prompt. Bootstrap validates that prompt source before linking the Zsh
entrypoints, so a partial checkout fails before changing shell files.

Zsh plugins are not symlinked. `install/lib/zsh-plugins.sh` clones them into
`${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins`, and `config/zsh/.zshrc`
resolves that same path into `ZSH_PLUGIN_DIR`. Cloning rather than installing
Homebrew formulae keeps one set of load paths valid on macOS and Linux; keeping
the clones outside the repo keeps upstream history out of it.

`config/bash/.bashrc` is intentionally standalone for Debian servers. It mirrors
only portable shell defaults and small aliases instead of sourcing zsh modules.
Zsh plugins, `eza`, and `zoxide` are not part of that Debian package set.

## Zsh Module Boundaries

- `config/zsh/options.zsh`: shell options, history behavior, and directory-stack options.
- `config/zsh/prompts/purification/`: vendored Prompt Purification source and
  upstream provenance. The repository-owned copy avoids per-machine prompt
  downloads and drift.
- `config/zsh/path.zsh`: login-shell `PATH` and path-like variable setup, sourced
  by `config/zsh/.zprofile`. Managed prefixes are declared once in effective
  precedence order, highest first. Mise shims lead that list and remain the only
  mise activation mechanism; the shims directory is resolved the same way mise
  resolves it (`MISE_DATA_DIR`, then `XDG_DATA_HOME`, then `~/.local/share`).
  Version-specific `pip install --user` directories are explicitly excluded.
- `config/zsh/env.zsh`: exported environment variables, including `FZF_*`
  defaults.
- `config/zsh/completion.zsh`: completion system configuration, including every
  `:completion:*` zstyle. Plain `compinit` audits completion paths on every
  startup, including with a cached dump. The menu style is conditional: fzf-tab can only
  capture the unambiguous prefix with zsh's own menu off, so `menu no` applies
  only when that plugin is present and `menu select=1` remains the fallback.
- `config/zsh/plugins.zsh`: tool shell integrations (fzf key bindings, zoxide)
  and plugin sourcing, plus the `:fzf-tab:*` zstyles that belong with the plugin
  they configure. Load order is load-bearing and documented in the file: fzf-tab
  after `compinit` and before anything that wraps ZLE widgets,
  fast-syntax-highlighting last. Every plugin is optional at runtime. fzf's ZLE
  integration requires terminal stdin/stdout and interactive ZLE; exported
  defaults and helper functions remain available in captured shells.
- `config/zsh/functions/*.zsh`: interactive helper functions (for example `fcd`, `ffcd`, `fview`, `fstack`).
- `config/zsh/aliases.zsh`: tracked shared aliases and short shell convenience commands. Machine/project-only overrides and modules belong in ignored `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`.

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

`install/lib/homebrew.sh` downloads the official Homebrew installer to a
temporary file and executes it with terminal input intact. This keeps the
macOS bootstrap interactive without coupling installer stdin to `curl`.

`install/lib/zsh-plugins.sh` owns the Zsh plugin manifest and its installer. It
installs missing plugins at full commit SHA pins with detached HEAD, verifies
origin URLs and clean worktrees, and fast-forwards existing clones to pins only
with `--upgrade-plugins`. Non-clone directories and symlinks are reported rather
than rewritten. `tests/install/zsh_plugins_test.sh` exercises it in both Bash
and Zsh against real local Git repositories, without network access.

## Ownership and Scope

- Managed by this repo:
  - symlink targets listed above
  - core package sets under `install/platforms/*/` and the optional, manually
    installed macOS creative/audio cask set
  - Go, Node.js, Pi, and pnpm versions declared in `config/mise/config.toml`
  - uv interpreter-selection behavior in `config/uv/uv.toml`
  - the Zsh Prompt Purification source and its reviewed upstream provenance
  - the Zsh plugin set in `install/lib/zsh-plugins.sh` and its clone directory
  - delta and lazygit diff-rendering configuration
- Not managed by this repo:
  - user secrets, keychains, tokens
  - `~/.gitconfig` beyond the single `include.path` entry described above
  - upstream plugin history; new clones are shallow, with ancestry fetched when
    needed to verify a pinned fast-forward update
  - arbitrary files in `$HOME` not explicitly linked
  - network tools outside `brew`, `mise`, `uv`, `winget`, `apt-get`, `git`, and `curl`

## Idempotency Goals

- Running bootstrap repeatedly should converge to one valid state.
- Existing valid symlinks should remain unchanged.
- Re-run noise should be minimal; destructive operations require explicit opt-in.

## Invariants

- Bootstrap wrappers are thin dispatchers (`install/bootstrap.sh` for macOS/Debian, `install/bootstrap.ps1` for Windows).
- Platform bootstrap scripts stay explicit under `install/platforms/{macos,windows,debian}/`.
- Shared bootstrap behavior and UI helpers live under `install/lib/`.
- Required package manifest and symlink targets must exist before mutation.
- Zsh-linking bootstraps require the vendored Prompt Purification source before
  advertising or linking the managed Zsh configuration.
- Existing Zsh plugin clones advance only under `--upgrade-plugins`, and only
  by fast-forward to manifest pins; general package upgrades do not update them.
  Unexpected origins, dirty clones, and non-fast-forward updates fail loudly
  instead of being silently merged or discarded.
- A plugin directory that is not a git clone is reported and left untouched.
- A missing plugin clone degrades the shell rather than breaking it.
- `install/platforms/macos/settings.zsh` is interactive, standalone, and never
  invoked by bootstrap.
- Debian package installation skips `apt-get update` and `apt-get install` when the apt manifest is already satisfied.
- Debian login shell changes require explicit `--force-shell`.

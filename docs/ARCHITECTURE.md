# Architecture

## Overview

Bootstrap links selected tracked files into `$HOME` and installs packages from
explicit manifests. The map below identifies those paths and exceptions.

## File-to-home mapping

- `config/zsh/.zshrc` and `config/zsh/.zprofile` -> `.zshrc` and `.zprofile`
  in `$HOME` on macOS and `${ZDOTDIR-$HOME}` on Debian (symlinks)
- `config/ghostty/config` -> `${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config` (symlink)
- `config/tmux/tmux.conf` -> `~/.tmux.conf` (symlink on macOS and Debian)
- `config/mise/config.toml` -> `${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml`
  (symlink on macOS). It tracks the latest Go, Node.js, pnpm, and Pi.
  Project mise configs,
  `.nvmrc`, `.node-version`,
  and `packageManager` metadata can override the active versions. Linking it to
  the path mise reads by default avoids environment-variable selection drift.
  The managed Zsh login PATH adds the mise shims; GUI and arbitrary non-shell
  processes do not necessarily inherit that PATH.
- `install/platforms/debian/mise.toml` -> `conf.d/dotfiles-debian.toml` under
  `${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}` (symlink on
  Debian/Ubuntu). This fragment selects `pi = "latest"` without replacing
  the user's `config.toml`. Bootstrap installs only Pi from mise's global
  configuration, outside the caller's project directory. If `mise` is missing,
  bootstrap fetches the official installer with `curl` and runs it as the
  current user to install `~/.local/bin/mise`. The existing Zsh login PATH
  picks up both that binary and the Pi shim.
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
- `config/alfred/` contains a theme and workflow for manual import, not links.
  Alfred keeps the selected vault in its ignored live `prefs.plist`. See
  [Alfred setup](ALFRED.md).
- `config/rectangle/RectangleConfig.json` contains curated Rectangle preferences
  for manual import, not a live plist link. Homebrew owns the app; Accessibility
  permission, login-item registration, native tiling, and Voyager modifier swaps
  remain per-machine setup. See [Rectangle setup](RECTANGLE.md).
- `install/platforms/macos/packages/` holds one Brewfile per package group
  and a `profiles` file naming the groups each profile installs. Bootstrap
  resolves `--profile`, `--with`, and `--without` with `install/lib/packages.sh`,
  concatenates the selected groups into one temporary Brewfile, and runs a
  single `brew bundle` pass. Each package lives in exactly one group; `core` is
  required. See [package profiles](OPERATIONS.md#package-profiles-and-groups).
- `creative.Brewfile` is in no profile and installs only with
  `--with creative`. It installs Unity Hub, not a rolling editor; Ableton stays
  vendor-managed.
- `install/platforms/windows/winget-packages.txt` is consumed by Windows bootstrap via `winget install`.
- `install/platforms/debian/apt-packages.txt` is consumed by Debian bootstrap via `apt-get install` after checking for missing packages.
- Windows bootstrap manages host applications through winget and explains WSL
  setup. It does not link native Windows shell files; Debian/Ubuntu in WSL uses
  the Debian Zsh/tmux bootstrap.

Both Zsh entrypoints find their checkout by resolving their symlinks unless
`DOTFILES_DIR` is explicitly set. `config/zsh/.zprofile` runs `brew shellenv`
when Homebrew is present at a standard macOS path, then sources
`config/zsh/path.zsh`, once, for login shells. That order is load-bearing:
`brew shellenv` prepends the Homebrew prefix to `PATH`, so running it after
`path.zsh` would place Homebrew's runtimes ahead of the mise shims and defeat
per-project version resolution. Interactive shells inherit the resulting
`PATH`; GUI and unrelated processes may not. `config/zsh/.zshrc` sources the
remaining shared `config/zsh/*.zsh` modules. `config/zsh/options.zsh` adds the
vendored Purification prompt to `fpath` and initializes it. Bootstrap validates
that prompt before linking the Zsh entrypoints, so a partial checkout fails
before changing shell files.

Zsh plugins are not symlinked. `install/lib/zsh-plugins.sh` clones them into
`$XDG_DATA_HOME/zsh/plugins`, falling back to `$HOME/.local/share/zsh/plugins`
when `XDG_DATA_HOME` is unset, empty, or relative. `config/zsh/.zshrc` resolves
that same path into `ZSH_PLUGIN_DIR`. Cloning rather than installing
Homebrew formulae keeps one set of load paths valid on macOS and Linux; keeping
the clones outside the repo keeps upstream history out of it.

`config/bash/.bashrc` remains available for manual reuse. Neither bootstrap
links it or changes existing Bash files.

## Zsh module boundaries

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
  startup, even with a cached dump. fzf-tab requires Zsh's menu off to capture
  the unambiguous prefix, so `menu no` applies only when it is present;
  `menu select=1` is the fallback.
- `config/zsh/plugins.zsh`: tool shell integrations (fzf key bindings, zoxide)
  and plugin sourcing, plus the `:fzf-tab:*` zstyles that belong with the plugin
  they configure. Load order is load-bearing and documented in the file: fzf-tab
  after `compinit` and before anything that wraps ZLE widgets,
  fast-syntax-highlighting last. Every plugin is optional at runtime. fzf's ZLE
  integration requires terminal stdin/stdout and interactive ZLE; exported
  defaults and helper functions remain available in captured shells.
- `config/zsh/functions/*.zsh`: interactive helper functions (for example `fcd`, `ffcd`, `fview`, `fstack`).
- `config/zsh/aliases.zsh`: tracked shared aliases and short shell commands.
  Put machine- and project-only overrides in ignored `config/zsh/local.zsh` or
  `config/zsh/local.d/*.zsh`.

## Symlink strategy

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
installs missing plugins at their upstream default branch tips with detached
HEAD, verifies origin URLs and clean worktrees, and fast-forwards existing
clones only with `--upgrade-plugins`. Non-clone directories and symlinks are reported rather
than rewritten. `tests/install/zsh_plugins_test.sh` exercises it in both Bash
and Zsh against real local Git repositories, without network access.

## Invariants

- `install/bootstrap.sh` and `install/bootstrap.ps1` dispatch to platform scripts;
  shared Unix bootstrap helpers live under `install/lib/`.
- Required package manifest and symlink targets must exist before mutation.
- Zsh-linking bootstraps require the vendored Prompt Purification source before
  advertising or linking the managed Zsh configuration.
- Existing Zsh plugin clones advance only under `--upgrade-plugins` and only
  by fast-forward to upstream HEAD. Unexpected origins, dirty clones, and
  non-clone directories are reported without overwriting them. Missing clones
  degrade the shell rather than breaking it.
- `install/platforms/macos/settings.zsh` is interactive, standalone, and never
  invoked by bootstrap.
- Debian package installation skips `apt-get update` and `apt-get install` when the apt manifest is already satisfied.
- Debian login shell changes require explicit `--force-shell`.

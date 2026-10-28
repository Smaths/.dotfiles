# Architecture

## Overview

Bootstrap links selected tracked files into `$HOME` and installs packages from
explicit manifests. The map below identifies those paths and exceptions.

## File-to-home mapping

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
- `config/alfred/` contains a theme and workflow for manual import, not links.
  Alfred keeps the selected vault in its ignored live `prefs.plist`. See
  [Alfred setup](ALFRED.md).
- `install/platforms/macos/Brewfile` is the core development/workstation
  manifest consumed by macOS bootstrap via `brew bundle`.
- `install/platforms/macos/Brewfile.creative` is optional and runs only with
  `--creative`. It installs Unity Hub, not a rolling editor; Ableton stays
  vendor-managed. See [creative installs](OPERATIONS.md#install-on-a-new-machine).
- `install/platforms/windows/winget-packages.txt` is consumed by Windows bootstrap via `winget install`.
- `install/platforms/debian/apt-packages.txt` is consumed by Debian bootstrap via `apt-get install` after checking for missing packages.
- Windows bootstrap manages host applications through winget and explains WSL
  setup. It does not link native Windows shell files; Debian/Ubuntu in WSL uses
  the Debian Bash/tmux bootstrap.

`config/zsh/.zprofile` runs `brew shellenv` and then sources
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
`${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins`, and `config/zsh/.zshrc`
resolves that same path into `ZSH_PLUGIN_DIR`. Cloning rather than installing
Homebrew formulae keeps one set of load paths valid on macOS and Linux; keeping
the clones outside the repo keeps upstream history out of it.

`config/bash/.bashrc` is intentionally standalone for Debian servers. It mirrors
only portable shell defaults and small aliases instead of sourcing zsh modules.
Zsh plugins, `eza`, and `zoxide` are not part of that Debian package set.

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
installs missing plugins at full commit SHA pins with detached HEAD, verifies
origin URLs and clean worktrees, and fast-forwards existing clones to pins only
with `--upgrade-plugins`. Non-clone directories and symlinks are reported rather
than rewritten. `tests/install/zsh_plugins_test.sh` exercises it in both Bash
and Zsh against real local Git repositories, without network access.

## Invariants

- `install/bootstrap.sh` and `install/bootstrap.ps1` dispatch to platform scripts;
  shared Unix bootstrap helpers live under `install/lib/`.
- Required package manifest and symlink targets must exist before mutation.
- Zsh-linking bootstraps require the vendored Prompt Purification source before
  advertising or linking the managed Zsh configuration.
- Existing Zsh plugin clones advance only under `--upgrade-plugins` and only
  by fast-forward to manifest pins. Unexpected origins, dirty clones, and
  non-clone directories are reported without overwriting them. Missing clones
  degrade the shell rather than breaking it.
- `install/platforms/macos/settings.zsh` is interactive, standalone, and never
  invoked by bootstrap.
- Debian package installation skips `apt-get update` and `apt-get install` when the apt manifest is already satisfied.
- Debian login shell changes require explicit `--force-shell`.

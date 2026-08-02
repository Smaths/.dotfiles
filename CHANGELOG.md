# Changelog

All notable changes to this dotfiles repo should be documented in this file.

## [Unreleased]

### Added

- Canonical docs set for architecture, platforms, and operations.
- Policy files: `.editorconfig`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`.
- Windows bootstrap entrypoint: `install/platforms/windows/bootstrap.ps1` with idempotent backup-before-symlink behavior.
- Windows package manifest: `install/platforms/windows/winget-packages.txt`.
- `Microsoft.WSL` and `Microsoft.WindowsTerminal` to `install/platforms/windows/winget-packages.txt`.
- Debian server bootstrap entrypoint: `install/platforms/debian/bootstrap.sh`.
- Debian apt package manifest: `install/platforms/debian/apt-packages.txt`.
- Debian bash shell config: `config/bash/.bashrc`.
- Unified bootstrap wrappers: `install/bootstrap.sh` for macOS/Debian and `install/bootstrap.ps1` for Windows.
- Shared Bash/Zsh bootstrap behavior helpers in `install/lib/common.sh`, with
  cross-shell symlink and dry-run tests.
- Shared Unix bootstrap UI helper: `install/lib/ui.sh`.
- Managed Node.js 24 LTS default, Node.js 22.12.0 compatibility runtime, and
  pnpm toolchain through `config/mise/config.toml`.
- A plain shell validation entrypoint at `tests/check.sh`, also run by CI.
- `jq` to the macOS Brewfile.
- Herdr, shell validation tools, tmux, Neovim, bat, uv, Git utilities, cloud
  CLIs, Android platform tools, .NET SDK, Unity Hub, and Zed to the macOS
  package manifest.
- ChatGPT and Claude desktop clients plus the Codex and Claude Code terminal
  agents to the macOS package manifest.
- Pi 0.82.1 as a mise-managed terminal agent.
- Prompt Purification vendored at its reviewed upstream commit and loaded from
  the tracked Zsh config instead of an unmanaged file under `~/.config`.

### Changed

- Replaced the proprietary Little Snitch macOS cask with the open-source LuLu
  firewall.
- macOS bootstrap now streams verbose Brew Bundle command output during parallel
  package installation instead of appearing idle after the fetch phase.
- `README.md` rewritten as LLM-legible project entrypoint with:
  - purpose and platform support
  - quick install flow
  - rollback/uninstall guidance
  - explicit safety defaults and off-limits notes
- `install/platforms/macos/settings.zsh` now starts with prompt mode selection:
  - use defaults (no per-setting prompts)
  - choose settings
  - skip
- Platform and operations docs now include Windows bootstrap usage and limits.
- macOS bootstrap now separates Homebrew resolution from first-time Homebrew installation in progress output.
- First-time Homebrew installation now downloads the official installer to a
  temporary file before executing it. This preserves interactive confirmation
  and `sudo` prompts and cleans up the installer after success or failure.
- Bootstrap failures now identify the active step instead of reporting an
  unavailable zsh command value as `unknown command`.
- macOS package and runtime installation commands now run in the foreground
  with native output and signal handling; background polling, temporary logs,
  and their cleanup traps were removed.
- macOS bootstrap now skips `brew bundle install` when the Brewfile is already
  satisfied and uses `--verbose --no-upgrade --jobs=auto` when package
  installation is needed.
- macOS bootstrap now supports `--upgrade-packages` to intentionally upgrade outdated Brewfile entries.
- Interactive macOS defaults are now an explicit standalone operation through
  `install/platforms/macos/settings.zsh`; bootstrap no longer invokes them or
  carries settings-specific skip flags and exit handling. Choosing Skip now
  exits successfully, and the unreachable second prompting path was removed.
- Windows bootstrap package installation now uses `winget` IDs instead of the macOS Homebrew manifest (`install/platforms/macos/Brewfile`).
- Windows bootstrap no longer links Ghostty config (Ghostty is not currently available via winget in this environment).
- Windows bootstrap now runs built-in checks for symlink capability, package ID validity, and post-link verification.
- Windows bootstrap is now WSL-first: it prints WSL commands for `zsh`/`tmux` setup and skips Windows-host zsh linking unless `--link-windows-shell` is specified.
- Documentation references were aligned to current canonical paths and filenames (`install/platforms/macos/Brewfile`, `docs/ARCHITECTURE.md`).
- Platform and operations docs now include Debian bash bootstrap usage and limits.
- macOS bootstrap lives at `install/platforms/macos/bootstrap.zsh`; `install/bootstrap.sh` dispatches to platform-specific Unix bootstraps.
- macOS bootstrap now installs pinned mise tools after Brew Bundle.
- The mise config is now symlinked to `$XDG_CONFIG_HOME/mise/config.toml`, the
  path mise reads by default, instead of being selected by an
  `MISE_GLOBAL_CONFIG_FILE` export from `config/zsh/env.zsh`. The export only
  reached shells that sourced `.zshrc`, so scripts, editors, git hooks, and
  other non-zsh processes silently resolved a different Node.js than the
  terminal did.
- mise is now activated solely through its shims on `PATH`; the redundant
  `mise activate zsh` call was removed from `config/zsh/env.zsh`. Shims cover
  interactive, login, non-interactive, and non-zsh contexts with one mechanism
  and still honor `.nvmrc`, `.node-version`, and `packageManager` pins.
- Node.js ownership moved from Homebrew `node` and nvm to mise; pnpm replaces
  the global Yarn baseline.
- The mise Node.js 24 LTS pin now tracks the current security release.
- mise now honors project-specific pnpm `packageManager` pins while keeping
  pnpm 11.19.0 as the single global default.
- The macOS package manifest now manages MySQL 8.4 LTS through `mysql@8.4`;
  Zsh selects its client and server binaries through `PATH`.
- `chruby` and `ruby-install` were removed from the macOS package manifest. They
  were sourced nowhere in the shell config and managed no Ruby installs; mise
  covers Ruby if it is ever needed.
- Static validation is now defined once, in `tests/check.sh`.
  `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, and `docs/LLM.md` previously each
  carried a full copy of the command list, which had to be edited in lockstep and
  had already drifted.
- The validation script derives its file sets from tracked and unignored files instead
  of hand-listed directories, so new scripts are covered before staging. The
  previous `shfmt` invocation missed `install/lib/ui.sh`, which was left
  unformatted as a result.
- `docs/llm.md` and `docs/platforms.md` were renamed to `docs/LLM.md` and
  `docs/PLATFORMS.md` to match the uppercase convention used by every other
  doc. The working tree already used uppercase while the index did not; because
  `core.ignorecase` is true on macOS, the mismatch was invisible locally but
  would have produced different filenames on a case-sensitive checkout.
- `config/zsh/.zprofile` now honors `DOTFILES_DIR` instead of hardcoding
  `$HOME/.dotfiles`, matching every other entrypoint.
- The `~/.config/mcp/bin` entry moved from `config/zsh/env.zsh` to
  `config/zsh/path.zsh` and is now guarded by a directory check. It previously
  bypassed the `path` array and landed ahead of every other entry, including the
  mise shims.
- `AGENTS.md` was removed from `.gitignore`; the file is tracked, so the ignore
  rule was contradictory and had no effect.
- `pnpm` is enabled alongside `node` in
  `idiomatic_version_file_enable_tools`, so mise reads project `packageManager`,
  `.nvmrc`, and `.node-version` declarations.
- Removed references to a `dot doctor` command that does not exist; direct mise,
  Node.js, and pnpm version checks cover that role.
- `docs/PLATFORMS.md` now records that the preflight/confirmation flow and the
  managed Node.js toolchain are Unix- and macOS-only respectively.
- Laravel Herd remains managed while its shadowed Homebrew Composer dependency
  was removed.
- Unity installation moved from the direct editor cask to Unity Hub.
- JetBrains IDE and Toolbox casks were removed in favor of VS Code, Zed, and
  Sublime Text.
- The supported macOS baseline is now 14+ to match current Homebrew and managed
  cask requirements.
- Unix bootstrap relinking now preserves incorrect symlinks and other existing
  paths in collision-safe timestamped backups while converged reruns remain a
  no-op.
- macOS and Debian bootstraps now use the same dry-run-aware command and symlink
  implementation; Debian dry runs report link steps as planned rather than
  linked and verified.
- Network-boundary documentation now includes mise runtime downloads.

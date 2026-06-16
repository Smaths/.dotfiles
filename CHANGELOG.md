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
- Shared Unix bootstrap UI helper: `install/lib/ui.sh`.

### Changed

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
- macOS bootstrap now skips `brew bundle install` when the Brewfile is already satisfied and uses `--no-upgrade --jobs=auto` when package installation is needed.
- macOS bootstrap now supports `--upgrade-packages` to intentionally upgrade outdated Brewfile entries.
- Windows bootstrap package installation now uses `winget` IDs instead of the macOS Homebrew manifest (`install/platforms/macos/Brewfile`).
- Windows bootstrap no longer links Ghostty config (Ghostty is not currently available via winget in this environment).
- Windows bootstrap now runs built-in checks for symlink capability, package ID validity, and post-link verification.
- Windows bootstrap is now WSL-first: it prints WSL commands for `zsh`/`tmux` setup and skips Windows-host zsh linking unless `--link-windows-shell` is specified.
- Documentation references were aligned to current canonical paths and filenames (`install/platforms/macos/Brewfile`, `docs/ARCHITECTURE.md`).
- Platform and operations docs now include Debian bash bootstrap usage and limits.
- macOS bootstrap lives at `install/platforms/macos/bootstrap.zsh`; `install/bootstrap.sh` dispatches to platform-specific Unix bootstraps.

# Changelog

All notable changes to this dotfiles repo should be documented in this file.

## [Unreleased]

### Added

- Canonical docs set for architecture, platforms, and operations.
- Policy files: `.editorconfig`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`.
- Windows bootstrap entrypoint: `install/bootstrap-windows.ps1` with idempotent backup-before-symlink behavior.
- Windows package manifest: `install/winget-packages.txt`.
- `Microsoft.WSL` and `Microsoft.WindowsTerminal` to `install/winget-packages.txt`.
- Debian server bootstrap entrypoint: `install/bootstrap-debian.sh`.
- Debian apt package manifest: `install/apt-packages.txt`.
- Debian bash shell config: `config/bash/.bashrc`.

### Changed

- `README.md` rewritten as LLM-legible project entrypoint with:
  - purpose and platform support
  - quick install flow
  - rollback/uninstall guidance
  - explicit safety defaults and off-limits notes
- `install/macos.zsh` now starts with prompt mode selection:
  - use defaults (no per-setting prompts)
  - choose settings
  - skip
- Platform and operations docs now include Windows bootstrap usage and limits.
- macOS bootstrap now separates Homebrew resolution from first-time Homebrew installation in progress output.
- macOS bootstrap now skips `brew bundle install` when the Brewfile is already satisfied and uses `--no-upgrade --jobs=auto` when package installation is needed.
- macOS bootstrap now supports `--upgrade-packages` to intentionally upgrade outdated Brewfile entries.
- Windows bootstrap package installation now uses `winget` IDs instead of the macOS Homebrew manifest (`install/Brewfile`).
- Windows bootstrap no longer links Ghostty config (Ghostty is not currently available via winget in this environment).
- Windows bootstrap now runs built-in checks for symlink capability, package ID validity, and post-link verification.
- Windows bootstrap is now WSL-first: it prints WSL commands for `zsh`/`tmux` setup and skips Windows-host zsh linking unless `--link-windows-shell` is specified.
- Documentation references were aligned to current canonical paths and filenames (`install/Brewfile`, `docs/ARCHITECTURE.md`).
- Platform and operations docs now include Debian bash bootstrap usage and limits.

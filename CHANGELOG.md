# Changelog

All notable changes to this dotfiles repo should be documented in this file.

## [Unreleased]

### Added

- Canonical docs set for architecture, platforms, and operations.
- Policy files: `.editorconfig`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`.
- Windows bootstrap entrypoint: `install/bootstrap-windows.ps1` with idempotent backup-before-symlink behavior.
- Windows package manifest: `install/winget-packages.txt`.
- `Microsoft.WSL` and `Microsoft.WindowsTerminal` to `install/winget-packages.txt`.

### Changed

- `README.md` rewritten as LLM-legible project entrypoint with:
  - purpose and platform support
  - quick install flow
  - rollback/uninstall guidance
  - explicit safety defaults and off-limits notes
- Platform and operations docs now include Windows bootstrap usage and limits.
- Windows bootstrap package installation now uses `winget` IDs instead of `brew/Brewfile`.
- Windows bootstrap no longer links Ghostty config (Ghostty is not currently available via winget in this environment).
- Windows bootstrap now runs built-in checks for symlink capability, package ID validity, and post-link verification.
- Windows bootstrap is now WSL-first: it prints WSL commands for `zsh`/`tmux` setup and skips Windows-host zsh linking unless `--link-windows-shell` is specified.

# Changelog

All notable changes to this dotfiles repo should be documented in this file.

## [Unreleased]

### Added

- Canonical docs set for architecture, platforms, and operations.
- Policy files: `.editorconfig`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`.

### Changed

- `README.md` rewritten as LLM-legible project entrypoint with:
  - purpose and platform support
  - quick install flow
  - rollback/uninstall guidance
  - explicit safety defaults and off-limits notes
- `install/macos.zsh` now starts with prompt mode selection:
  - use recommended defaults
  - customize prompt defaults, then continue
  - manual prompts (default No), preserving prior behavior

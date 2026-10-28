# AGENTS.md

## Goal

Maintain a safe, repeatable setup for macOS 14+, Windows host apps, and
Debian/Ubuntu shells in WSL or on a server. Other Linux distributions can reuse
config but have no supported bootstrap. See [platform details](docs/PLATFORMS.md).

## Canonical entrypoints

- Unix install/bootstrap wrapper: `install/bootstrap.sh`
- Windows install/bootstrap wrapper: `install/bootstrap.ps1`
- macOS install/bootstrap: `install/platforms/macos/bootstrap.zsh`
- Windows install/bootstrap: `install/platforms/windows/bootstrap.ps1`
- Debian install/bootstrap: `install/platforms/debian/bootstrap.sh`
- Optional macOS settings: `install/platforms/macos/settings.zsh`
- Shared Unix bootstrap helpers: `install/lib/common.sh`,
  `install/lib/homebrew.sh`, `install/lib/ui.sh`,
  `install/lib/zsh-plugins.sh`
- macOS core package manifest: `install/platforms/macos/Brewfile`
- Optional macOS creative/audio manifest: `install/platforms/macos/Brewfile.creative`
  (included by macOS bootstrap only with `--creative`)
- Windows package manifest: `install/platforms/windows/winget-packages.txt`
- Debian package manifest: `install/platforms/debian/apt-packages.txt`
- Diff rendering config: `config/git/delta.gitconfig`, `config/lazygit/config.yml`
- Zsh startup chain: `config/zsh/.zprofile` -> `config/zsh/path.zsh`, then
  `config/zsh/.zshrc` -> interactive `config/zsh/*.zsh` modules
- Debian bash entrypoint: `config/bash/.bashrc`
- Alfred workflow and theme: `config/alfred/` (manual import)

## Non-negotiables

- Idempotency first: reruns should converge and avoid duplicate state.
- No destructive operations without explicit `--force` style opt-in.
- Never commit secrets, tokens, keys, or credentials.
- Keep network behavior within the documented tools (`brew`, `mise`, `uv`,
  `winget`, `apt-get`, `git`, `curl`); document and justify any proposed addition before implementation.
- Windows bootstrap manages host apps only. Do not add native Windows Zsh linking; WSL shell setup uses Debian/Ubuntu Bash/tmux.
- Keep machine-specific/project-only shell modules in ignored `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`; do not add them to tracked shared modules.
- The macOS `Brewfile` is the core workstation manifest. Keep its ordering
  unless a change requires otherwise. Install the sole optional creative/audio
  manifest, `Brewfile.creative`, only with `--creative`. Do not add more profiles.
- Keep package ownership explicit. Homebrew owns macOS native apps; mise owns
  its declared runtimes and tools; uv owns Python interpreters and environments;
  winget owns Windows host apps; apt owns Debian packages. Project dependencies
  belong in project manifests and lockfiles.
- mise shims are exposed through the managed Zsh login PATH; do not claim all GUI or non-shell processes inherit that PATH.
- `~/.gitconfig` is user-owned. The only permitted write is the single
  `include.path` entry for `config/git/delta.gitconfig`.
- Zsh plugin clones are fast-forward only, and a directory that is not a git
  clone is reported rather than replaced.

## Change workflow

1. Update manifest/config source of truth (`install/platforms/*/`, `config/*`).
2. Update automation step scripts (`install/*.zsh`, `install/*.ps1`, `install/*.sh`) if behavior changed.
3. Update relevant docs (`README.md`, `docs/*.md`).
4. Run required checks:
   - `bash tests/check.sh` (static validation and shared helper tests; also run by CI)
   - `brew bundle check --no-upgrade --file ~/.dotfiles/install/platforms/macos/Brewfile`
   - `winget search --id <ID> -e` for each `install/platforms/windows/winget-packages.txt` entry
   - On Debian: `sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages`

## Pointers

- Architecture: `docs/ARCHITECTURE.md`
- Platforms/prereqs: `docs/PLATFORMS.md`
- Operations: `docs/OPERATIONS.md`
- Contribution rules: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`
- Alfred workflow and theme import: `docs/ALFRED.md`

# AGENTS.md

## Goal

Maintain a safe, idempotent dotfiles repo for a macOS-first workstation, Windows host applications, and Debian/Ubuntu WSL or Debian server shell setup.

## Supported Platforms

- Primary: macOS 14+
- Secondary: Windows host-app bootstrap via PowerShell; shell setup belongs in Debian/Ubuntu WSL
- Secondary: Debian server and WSL bootstrap via bash
- Secondary: Other Linux config reuse only

## Canonical Entrypoints

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
- Zsh plugin manifest: `install/lib/zsh-plugins.sh`
- Diff rendering config: `config/git/delta.gitconfig`, `config/lazygit/config.yml`
- Zsh startup chain: `config/zsh/.zprofile` -> `config/zsh/path.zsh`, then
  `config/zsh/.zshrc` -> interactive `config/zsh/*.zsh` modules
- Debian bash entrypoint: `config/bash/.bashrc`

## Non-Negotiables

- Idempotency first: reruns should converge and avoid duplicate state.
- No destructive operations without explicit `--force` style opt-in.
- Never commit secrets, tokens, keys, or credentials.
- Keep network behavior within the documented tools (`brew`, `mise`, `uv`,
  `winget`, `apt-get`, `git`, `curl`); document and justify any proposed addition before implementation.
- Windows bootstrap manages host apps only. Do not add native Windows Zsh linking; WSL shell setup uses Debian/Ubuntu Bash/tmux.
- Keep machine-specific/project-only shell modules in ignored `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`; do not add them to tracked shared modules.
- The macOS `Brewfile` is the core workstation manifest. `Brewfile.creative` is the sole optional creative/audio manifest and is installed only with explicit `--creative`; do not add more package profiles.
- Keep package ownership explicit: Homebrew owns macOS native apps, mise its declared runtimes/tools, uv Python interpreters/environments, winget Windows host apps, and apt Debian packages. Project dependencies belong in project manifests and lockfiles.
- mise shims are exposed through the managed Zsh login PATH; do not claim all GUI or non-shell processes inherit that PATH.
- `~/.gitconfig` is user-owned. The only permitted write is the single
  `include.path` entry for `config/git/delta.gitconfig`.
- Zsh plugin clones are fast-forward only, and a directory that is not a git
  clone is reported rather than replaced.

## Change Workflow

1. Update manifest/config source of truth (`install/platforms/*/`, `config/*`).
2. Update automation step scripts (`install/*.zsh`, `install/*.ps1`, `install/*.sh`) if behavior changed.
3. Update docs (`README.md`, `docs/*.md`, `CHANGELOG.md`).
4. Run required checks:
   - `bash tests/check.sh` (static validation and shared helper tests; also run by CI)
   - `brew bundle check --no-upgrade --file ~/.dotfiles/install/platforms/macos/Brewfile`
   - `winget search --id <ID> -e` for each `install/platforms/windows/winget-packages.txt` entry
   - On Debian: `sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages`

## Pointers

- Architecture: `docs/ARCHITECTURE.md`
- Platforms/prereqs: `docs/PLATFORMS.md`
- Operations: `docs/OPERATIONS.md`
- LLM operating notes: `docs/LLM.md`
- Contribution rules: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`

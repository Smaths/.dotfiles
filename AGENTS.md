# AGENTS.md

## Goal

Maintain a safe, idempotent dotfiles repo for reproducible macOS-first workstation and Debian server setup.

## Supported Platforms

- Primary: macOS 13+
- Secondary: Windows bootstrap via PowerShell
- Secondary: Debian server bootstrap via bash
- Secondary: Other Linux config reuse only

## Canonical Entrypoints

- Unix install/bootstrap wrapper: `install/bootstrap.sh`
- Windows install/bootstrap wrapper: `install/bootstrap.ps1`
- macOS install/bootstrap: `install/platforms/macos/bootstrap.zsh`
- Windows install/bootstrap: `install/platforms/windows/bootstrap.ps1`
- Debian install/bootstrap: `install/platforms/debian/bootstrap.sh`
- Optional macOS settings: `install/platforms/macos/settings.zsh`
- Shared Unix bootstrap UI: `install/lib/ui.sh`
- macOS package manifest: `install/platforms/macos/Brewfile`
- Windows package manifest: `install/platforms/windows/winget-packages.txt`
- Debian package manifest: `install/platforms/debian/apt-packages.txt`
- Shell entrypoint chain: `config/zsh/.zshrc` -> `config/zsh/*.zsh`
- Debian bash entrypoint: `config/bash/.bashrc`

## Non-Negotiables

- Idempotency first: reruns should converge and avoid duplicate state.
- No destructive operations without explicit `--force` style opt-in.
- Never commit secrets, tokens, keys, or credentials.
- Do not expand network behavior beyond documented tools (`brew`, `winget`, `apt-get`, `git`, `curl`) without explicit documentation updates.

## Change Workflow

1. Update manifest/config source of truth (`install/platforms/*/`, `config/*`).
2. Update automation step scripts (`install/*.zsh`, `install/*.ps1`, `install/*.sh`) if behavior changed.
3. Update docs (`README.md`, `docs/*.md`, `CHANGELOG.md`).
4. Run required checks:
   - `shellcheck install/*.sh install/lib/*.sh install/platforms/*/*.sh install/platforms/*/*.zsh config/zsh/*.zsh config/bash/*.bash config/bash/.bashrc`
   - `shfmt -w -i 2 -ci install/platforms/*/*.zsh config/zsh/*.zsh`
   - `sh -n install/bootstrap.sh`
   - `sh -n install/lib/ui.sh`
   - `bash -n install/platforms/debian/bootstrap.sh config/bash/.bashrc`
   - `brew bundle check --file ~/.dotfiles/install/platforms/macos/Brewfile`
   - `winget search --id <ID> -e` for each `install/platforms/windows/winget-packages.txt` entry
   - On Debian: `sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages`
   - If available: `dot doctor`

## Pointers

- Architecture: `docs/ARCHITECTURE.md`
- Platforms/prereqs: `docs/platforms.md`
- Operations: `docs/OPERATIONS.md`
- LLM operating notes: `docs/llm.md`
- Contribution rules: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`

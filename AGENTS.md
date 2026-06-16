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
- macOS install/bootstrap: `install/bootstrap-macos.zsh`
- Windows install/bootstrap: `install/bootstrap-windows.ps1`
- Debian install/bootstrap: `install/bootstrap-debian.sh`
- Optional macOS tuning: `install/macos.zsh`
- Package manifest: `install/Brewfile`
- Windows package manifest: `install/winget-packages.txt`
- Debian package manifest: `install/apt-packages.txt`
- Shell entrypoint chain: `config/zsh/.zshrc` -> `config/zsh/*.zsh`
- Debian bash entrypoint: `config/bash/.bashrc`

## Non-Negotiables

- Idempotency first: reruns should converge and avoid duplicate state.
- No destructive operations without explicit `--force` style opt-in.
- Never commit secrets, tokens, keys, or credentials.
- Do not expand network behavior beyond documented tools (`brew`, `winget`, `apt-get`, `git`, `curl`) without explicit documentation updates.

## Change Workflow

1. Update manifest/config source of truth (`install/Brewfile`, `install/winget-packages.txt`, `install/apt-packages.txt`, `config/*`).
2. Update automation step scripts (`install/*.zsh`, `install/*.ps1`, `install/*.sh`) if behavior changed.
3. Update docs (`README.md`, `docs/*.md`, `CHANGELOG.md`).
4. Run required checks:
   - `shellcheck install/*.zsh config/zsh/*.zsh`
   - `shellcheck install/*.sh config/bash/*.bash config/bash/.bashrc`
   - `shfmt -w -i 2 -ci install/*.zsh config/zsh/*.zsh`
   - `sh -n install/bootstrap.sh`
   - `bash -n install/bootstrap-debian.sh config/bash/.bashrc`
   - `brew bundle check --file ~/.dotfiles/install/Brewfile`
   - `winget search --id <ID> -e` for each `install/winget-packages.txt` entry
   - On Debian: `sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages`
   - If available: `dot doctor`

## Pointers

- Architecture: `docs/ARCHITECTURE.md`
- Platforms/prereqs: `docs/platforms.md`
- Operations: `docs/operations.md`
- LLM operating notes: `docs/llm.md`
- Contribution rules: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`

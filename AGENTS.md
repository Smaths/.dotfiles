# AGENTS.md

## Goal

Maintain a safe, idempotent dotfiles repo for reproducible macOS-first workstation setup.

## Supported Platforms

- Primary: macOS 13+
- Secondary: Windows bootstrap via PowerShell
- Secondary: Linux config reuse only

## Canonical Entrypoints

- Install/bootstrap: `install/bootstrap.zsh`
- Windows install/bootstrap: `install/bootstrap-windows.ps1`
- Optional macOS tuning: `install/macos.zsh`
- Package manifest: `brew/Brewfile`
- Windows package manifest: `install/winget-packages.txt`
- Shell entrypoint chain: `config/zsh/.zshrc` -> `config/zsh/*.zsh`

## Non-Negotiables

- Idempotency first: reruns should converge and avoid duplicate state.
- No destructive operations without explicit `--force` style opt-in.
- Never commit secrets, tokens, keys, or credentials.
- Do not expand network behavior beyond documented tools (`brew`, `winget`, `git`, `curl`) without explicit documentation updates.

## Change Workflow

1. Update manifest/config source of truth (`brew/Brewfile`, `install/winget-packages.txt`, `config/*`).
2. Update automation step scripts (`install/*.zsh`, `install/*.ps1`) if behavior changed.
3. Update docs (`README.md`, `docs/*.md`, `CHANGELOG.md`).
4. Run required checks:
   - `shellcheck install/*.zsh config/zsh/*.zsh`
   - `shfmt -w -i 2 -ci install/*.zsh config/zsh/*.zsh`
   - `brew bundle check --file ~/.dotfiles/brew/Brewfile`
   - `winget search --id <ID> -e` for each `install/winget-packages.txt` entry
   - If available: `dot doctor`

## Pointers

- Architecture: `docs/architecture.md`
- Platforms/prereqs: `docs/platforms.md`
- Operations: `docs/operations.md`
- LLM operating notes: `docs/llm.md`
- Contribution rules: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`

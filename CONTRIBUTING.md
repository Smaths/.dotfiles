# Contributing

## Scope

This repo prioritizes safe, repeatable workstation setup. Contributions should
preserve idempotency and avoid unexpected side effects. Windows changes manage
host applications only; shell setup belongs in Debian/Ubuntu WSL or the Debian
server bootstrap.

## Standards

- Prefer `zsh` (existing scripts) or POSIX `sh` when portability is required.
- Use strict mode in scripts:
  - `set -euo pipefail`
- Keep scripts idempotent:
  - reruns should converge and avoid duplicate state.
- No destructive operations by default.
  - destructive behavior must require explicit `--force` or equivalent opt-in.
- Keep defaults conservative and reversible.

## Network and External Calls

Allowed by default:

- `brew` (macOS package management)
- `mise` (managed runtimes/tools)
- `uv` (Python interpreters/environments/tools)
- `winget` (Windows host applications)
- `apt-get` (Debian package management)
- `git` (source sync)
- `curl` (bootstrap/downloads)

Keep network access within these canonical tools. Any proposed addition must be justified in the documentation/PR description and kept minimal. Homebrew owns native standalone apps; mise owns the declared runtime tools; uv owns Python interpreters and environments; project dependencies belong in project manifests and lockfiles. The macOS Brewfile is the core manifest; the creative manifest is optional and manual.

## Lint and Formatting

- Shell scripts should pass `shellcheck` where practical.
- Format shell files with `shfmt` (2-space indentation).
- Keep comments concise and operationally useful.

Suggested local checks:

```zsh
bash tests/check.sh
```

This is the same script CI runs. Add new checks there rather than duplicating
the command list in documentation.

## Documentation Requirements

Behavior-changing PRs should update:

- `README.md` (if user-facing behavior changes)
- `docs/ARCHITECTURE.md` (if mapping/symlink strategy changes)
- `docs/OPERATIONS.md` (if install/update/recovery flows change)
- `CHANGELOG.md` (`[Unreleased]`)

# Contributing

## Scope

This repo prioritizes safe, repeatable workstation setup. Contributions should
preserve idempotency and avoid unexpected side effects.

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

- `brew` (package management)
- `apt-get` (Debian package management)
- `git` (source sync)
- `curl` (bootstrap/downloads)

Anything beyond this should be justified in docs/PR description and kept minimal.

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

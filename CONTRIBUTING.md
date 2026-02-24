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
- `git` (source sync)
- `curl` (bootstrap/downloads)

Anything beyond this should be justified in docs/PR description and kept minimal.

## Lint and Formatting

- Shell scripts should pass `shellcheck` where practical.
- Format shell files with `shfmt` (2-space indentation).
- Keep comments concise and operationally useful.

Suggested local checks:

```zsh
shellcheck install/*.zsh config/zsh/*.zsh
shfmt -w -i 2 -ci install/*.zsh config/zsh/*.zsh
```

## Documentation Requirements

Behavior-changing PRs should update:

- `README.md` (if user-facing behavior changes)
- `docs/architecture.md` (if mapping/symlink strategy changes)
- `docs/operations.md` (if install/update/recovery flows change)
- `CHANGELOG.md` (`[Unreleased]`)

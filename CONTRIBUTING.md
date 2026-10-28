# Contributing

## Scope

Keep installs repeatable and preserve user files. Windows changes manage host
apps only; shell setup belongs in Debian/Ubuntu WSL or the Debian bootstrap.

## Standards

- Prefer `zsh` (existing scripts) or POSIX `sh` when portability is required.
- Use strict mode where the script's shell supports it (`set -euo pipefail`
  in Bash and Zsh).
- Make reruns converge without duplicate state.
- Gate destructive behavior behind an explicit `--force` or equivalent opt-in.

## Network and external calls

Keep network calls within `brew`, `mise`, `uv`, `winget`, `apt-get`, `git`, and
`curl`. Justify any additional tool in the PR or docs before using it.

Homebrew owns native apps; mise owns declared tools; uv owns Python. Project
dependencies belong in project manifests and lockfiles. Keep the macOS Brewfile
as the core manifest; `Brewfile.creative` runs only with `--creative`.

## Lint and formatting

- Shell scripts should pass `shellcheck` where practical.
- Format shell files with `shfmt` (2-space indentation).
- Keep comments concise and operationally useful.

Run:

```zsh
bash tests/check.sh
```

CI runs the same script; add new checks there.

## Documentation requirements

Behavior-changing PRs should update:

- `README.md` (if user-facing behavior changes)
- `docs/ARCHITECTURE.md` (if mapping/symlink strategy changes)
- `docs/OPERATIONS.md` (if install/update/recovery flows change)
- `docs/ALFRED.md` (if Alfred import or workflow behavior changes)

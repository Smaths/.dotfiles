# Contributing

## Scope

Keep installs repeatable and preserve user files. Windows changes manage host
apps only; shell setup belongs in Debian/Ubuntu WSL or the Debian bootstrap.

## Working on main

For small edits, review the diff, run the relevant checks, and push directly
to `main`. For larger changes or concurrent work, use topic branches and
separate worktrees. Review and test each branch, then merge it locally before
pushing `main`. Worktrees isolate working directories; they don't require PRs.

The GitHub ruleset for `main` blocks force pushes and branch deletion with
no bypass actors. It does not require PRs, reviews, signed commits, a merge
queue, or passing status checks. The `checks` workflow still runs on every
push. Keep outside collaborator access disabled by not granting access or
sending invitations.

If agents start merging unattended, consider requiring PRs with zero required
approvals and a few fast CI checks. That would give automation a check before
merging without requiring you to approve your own changes.

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
dependencies belong in project manifests and lockfiles. Add each macOS package
to exactly one group in `install/platforms/macos/packages/`; profiles only name
groups. See the package rules in [AGENTS.md](AGENTS.md).

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

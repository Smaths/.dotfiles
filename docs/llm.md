# LLM Operating Manual

## Repo Goals

- Idempotent setup: reruns should converge without breaking user state.
- Minimal prompting: scripts should make safe default choices and require little hand-holding.
- Safe operations: prefer reversible changes and explicit opt-in for risky actions.

## Edit Order (Preferred)

1. Manifest layer:
   - `install/Brewfile`
   - `install/winget-packages.txt`
   - `install/apt-packages.txt`
   - tracked config files under `config/`
2. Step scripts:
   - `install/bootstrap.sh`
   - `install/bootstrap.ps1`
   - `install/bootstrap-macos.zsh`
   - `install/bootstrap-windows.ps1`
   - `install/bootstrap-debian.sh`
   - `install/macos.zsh`
3. Documentation:
   - `README.md`
   - `docs/*.md`
   - `CHANGELOG.md`

Reason: behavior should be changed at the source first, then automation, then docs.

## Do / Don't

Do:

- Keep scripts idempotent and non-destructive by default.
- Preserve user files via backup-before-relink patterns.
- Add comments only where logic is non-obvious.
- Update docs when behavior changes.

Don't:

- Reorder `install/Brewfile` entries without a concrete reason.
- Inline secrets/tokens/credentials in tracked files.
- Add unreviewed `curl|sh` patterns beyond the explicit Homebrew bootstrap path.
- Add destructive operations without an explicit `--force` style gate.

## Required Checks Before Finalizing

Run from repo root:

```zsh
shellcheck install/*.zsh config/zsh/*.zsh
shellcheck install/*.sh config/bash/*.bash config/bash/.bashrc
shfmt -w -i 2 -ci install/*.zsh config/zsh/*.zsh
sh -n install/bootstrap.sh
bash -n install/bootstrap-debian.sh config/bash/.bashrc
brew bundle check --file ~/.dotfiles/install/Brewfile
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
```

If a `dot doctor` command exists in the local environment, run that too.

## Off-Limits

- Never commit secrets.
- Do not assume generic Linux bootstrap support exists; Debian is the supported Linux server bootstrap target.
- `install/bootstrap.sh` dispatches only to macOS and Debian bootstraps; use `install/bootstrap.ps1` for Windows.
- Do not silently expand network dependencies beyond documented tools (`brew`, `winget`, `apt-get`, `git`, `curl`).

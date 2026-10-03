# LLM Operating Manual

## Repo Goals

- Idempotent setup: reruns should converge without breaking user state.
- Minimal prompting: scripts should make safe default choices and require little hand-holding.
- Safe operations: prefer reversible changes and explicit opt-in for risky actions.

## Edit Order (Preferred)

1. Manifest layer:
   - `install/platforms/macos/Brewfile`
   - `install/platforms/windows/winget-packages.txt`
   - `install/platforms/debian/apt-packages.txt`
   - tracked config files under `config/`
2. Step scripts:
   - `install/bootstrap.sh`
   - `install/bootstrap.ps1`
   - `install/platforms/macos/bootstrap.zsh`
   - `install/platforms/windows/bootstrap.ps1`
   - `install/platforms/debian/bootstrap.sh`
   - `install/platforms/macos/settings.zsh`
   - `install/lib/common.sh`
   - `install/lib/homebrew.sh`
   - `install/lib/ui.sh`
   - `install/lib/zsh-plugins.sh`
3. Documentation:
   - `README.md`
   - `docs/*.md`
   - `CHANGELOG.md`

Reason: behavior should be changed at the source first, then automation, then docs.

## Do / Don't

Do:

- Keep scripts idempotent and non-destructive by default.
- Preserve user files via backup-before-relink patterns.
- Keep machine/project-only shell commands in ignored `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`, not tracked shared aliases.
- Keep package ownership clear: Homebrew owns native apps, mise its declared tools, uv Python environments, winget Windows host applications, and apt Debian packages; project dependencies remain project-local.
- Treat mise shim availability as PATH-dependent: managed Zsh login shells receive it, but GUI and arbitrary non-shell processes do not necessarily inherit it.
- Add comments only where logic is non-obvious.
- Update docs when behavior changes.

Don't:

- Reorder `install/platforms/macos/Brewfile` entries without a concrete reason.
- Inline secrets/tokens/credentials in tracked files.
- Pipe downloaded scripts directly into a shell; download them to a temporary
  file first so failures and terminal behavior remain observable.
- Add destructive operations without an explicit `--force` style gate.

## Required Checks Before Finalizing

Run from repo root:

```zsh
bash tests/check.sh
brew bundle check --no-upgrade --file ~/.dotfiles/install/platforms/macos/Brewfile
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
zsh -i -c 'typeset -f prompt_purification_setup >/dev/null && echo ok'
zsh -i -c '[[ -n $widgets[fzf-tab-complete] ]] && echo ok'
zsh -i -c 'typeset -f z >/dev/null && echo ok'
git config --get core.pager
```

Run `mise current`, `node --version`, `pnpm --version`, and `pi --version` to
confirm the managed tool versions.
Run `uv python list --only-installed` to confirm uv-managed Python interpreters;
standalone native CLIs remain Homebrew-owned.

## Off-Limits

- Never commit secrets.
- Do not assume generic Linux bootstrap support exists; Debian is the supported Linux server bootstrap target.
- `install/bootstrap.sh` dispatches only to macOS and Debian (including Debian/Ubuntu WSL); use `install/bootstrap.ps1` for Windows host applications. Native Windows shell links are not managed.
- Do not silently expand network dependencies beyond documented tools (`brew`,
  `mise`, `uv`, `winget`, `apt-get`, `git`, `curl`).
- Do not write to `~/.gitconfig` beyond the single `include.path` entry for
  `config/git/delta.gitconfig`; that file is user-owned.
- Do not replace or reset a Zsh plugin directory that is not a git clone.
- Keep `install/platforms/macos/Brewfile` as the core manifest. `Brewfile.creative` is the sole optional creative/audio manifest and is installed only with explicit `--creative`; do not introduce more package profiles.

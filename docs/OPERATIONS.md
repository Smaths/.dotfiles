# Operations

## Install on a new machine

Start with the platform commands in the [Quick start](../README.md#quick-start).
Available bootstrap flags:

- `--dry-run`: print intended actions without mutating.
- `--yes`: run without interactive confirmation on macOS, Windows, and Debian.
- `--verbose`: show extra command detail.
- `--upgrade-packages` (macOS only): upgrade outdated selected Brewfile entries
  during bootstrap.
- `--upgrade-plugins` (macOS only): fast-forward existing Zsh plugin clones to
  the exact manifest pins, independently of package upgrades.
- `--creative` (macOS only): also install the optional creative/audio casks in
  `Brewfile.creative`; the default installs the core Brewfile only.
- `--skip-packages` (Windows only): skip `winget` installs.
- Windows does not support native shell linking; the retired `--link-windows-shell` option is rejected. Use the Debian/Ubuntu bootstrap inside WSL.
- `--skip-packages` (Debian only): skip `apt-get` installs.
- `--force-shell` (Debian only): change the current user's login shell to bash.

Interactive runs ask before changes. Unattended installs require `--yes`;
use `--dry-run` to preview instead.

macOS settings run separately from bootstrap:

```zsh
zsh ~/.dotfiles/install/platforms/macos/settings.zsh
```

The settings script offers three modes:

- `1) Use defaults (no per-setting prompts)`: applies repo defaults after confirmation.
- `2) Choose settings`: set defaults for each setting, then proceed.
- `3) Skip`: exits macOS tuning without applying defaults.

To install the optional creative/audio casks alongside the core set:

```zsh
sh ~/.dotfiles/install/bootstrap.sh --creative
```

To install only that manifest without running the rest of bootstrap:

```zsh
brew bundle install --no-upgrade \
  --file ~/.dotfiles/install/platforms/macos/Brewfile.creative
```

Ableton Live remains vendor-managed. The creative manifest installs Unity Hub,
not Homebrew's rolling `unity` editor; use each project's
`ProjectSettings/ProjectVersion.txt` to select an editor in Hub or Unity CLI.
`brew bundle cleanup` against either manifest treats the other's packages as
unlisted. Compare both manifests and preview cleanup before considering `--force`.

Alfred workflow and theme files require manual import. See
[Alfred setup](ALFRED.md) for the package command, vault setting, and import
precautions.

## Update an existing machine

```zsh
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh
```

On macOS, bootstrap skips Brew Bundle when the core manifest is satisfied.
Otherwise it runs `brew bundle install --verbose --no-upgrade --jobs=auto` to
add missing entries without upgrading existing ones. Up to four formula installs
can run in parallel, so output may interleave. Brew Bundle and mise run in the
foreground with their normal output and signal handling.

The vendored Prompt Purification needs no separate install; bootstrap validates
it before linking `~/.zshrc`. Bootstrap links `config/mise/config.toml` at mise's
standard XDG path, then runs `mise install` for the pinned Go, Node.js, Pi, and
pnpm tools. Project mise files, `.nvmrc`, `.node-version`, and `packageManager`
metadata can select other versions. The managed Zsh login PATH exposes mise
shims; GUI apps and unrelated processes may not inherit that PATH.

Bootstrap also links `config/uv/uv.toml`. uv uses its own Python interpreters
without altering Apple/Xcode Python or its user-package PATH. Homebrew owns
native standalone apps such as the OpenAI CLI.

Zsh plugins are pinned by full commit SHA in `install/lib/zsh-plugins.sh`.
Missing plugins are fetched at that exact commit and installed with detached
HEAD; bootstrap never checks out a floating upstream branch. Existing clones
are checked for the expected origin URL and a clean worktree (including
untracked files). A mismatched pin is reported, not silently updated.
`--upgrade-packages` does not advance existing plugins. To apply a reviewed pin
change, use:

```zsh
sh install/bootstrap.sh --dry-run --upgrade-plugins
sh install/bootstrap.sh --upgrade-plugins
```

Updates verify the fetched commit and require the installed HEAD to be an
ancestor of the pin. Shallow clones fetch the target's history to prove this.
Divergent/ahead commits, dirty worktrees, and unexpected or multiple origin URLs
fail without resetting or discarding files. Non-clone directories and symlinks
are reported and left untouched. Dry runs do not fetch or modify clones; the
ancestry check is deferred until the real run. An already-current pin needs no
network access.

### Plugin pin review

The pins in `install/lib/zsh-plugins.sh` preserve a clean installed baseline
with verified origins rather than selecting newer upstream commits. That
baseline check is not a full security audit of upstream code.
For future updates, fetch the candidate into a separate review clone, inspect
`git diff OLD_SHA NEW_SHA` (especially sourced files, subprocesses, and network
or build hooks), and test it before recording the full SHA in the manifest.
Commit the manifest change with review notes, run `bash tests/check.sh`, then
explicitly apply it with `--upgrade-plugins`. Never use branch names or tags as
pins. Backward or divergent pin changes need manual review and relocation of
the old clone before reinstalling; bootstrap never forces them.

To intentionally upgrade outdated Homebrew packages and casks during bootstrap:

```zsh
sh install/bootstrap.sh --upgrade-packages
```

For unattended maintenance, pass `--yes` explicitly:

```zsh
sh install/bootstrap.sh --yes
```

Go, Node.js, Pi, and pnpm upgrades are intentional config changes rather than
side effects of a Homebrew upgrade. Update the defaults, review the diff, then
rerun bootstrap. Keep project runtime and package-manager pins until their
projects are tested on newer versions.

Pi is installed as a standalone executable, so `pi update` cannot replace the
executable and may report its internal Bun path (`/$bunfs/root/pi`). Update the
Pi pin in `config/mise/config.toml` and run `mise install` instead. Use
`pi update --extensions` only to update configured Pi extensions.

```zsh
${EDITOR:-vi} ~/.dotfiles/config/mise/config.toml
mise install
sh install/bootstrap.sh
```

Check the versions selected in a project directory before installing
dependencies:

```zsh
mise current
go version
node --version
npm --version   # npm projects
pnpm --version  # pnpm projects
pi --version
```

Windows update flow:

```powershell
Set-Location $HOME/.dotfiles
git pull --ff-only
powershell -ExecutionPolicy Bypass -File install/bootstrap.ps1 --skip-packages
```

Debian update flow:

```bash
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh --skip-packages
```

Without `--skip-packages`, Debian bootstrap checks `install/platforms/debian/apt-packages.txt`
first and skips `apt-get update`/`apt-get install` when every manifest package
is already installed. If packages are missing, it updates apt metadata and
installs only the missing package names.

## Health checks

Run `bash tests/check.sh` for static and helper checks. CI also verifies a
pinned `shfmt` binary because Ubuntu's package cannot parse this repo's Zsh.
On an installed machine, check the relevant paths and tools:

```zsh
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
brew bundle check --no-upgrade --file ~/.dotfiles/install/platforms/macos/Brewfile
test -L ~/.config/mise/config.toml && readlink ~/.config/mise/config.toml
mise current
go version
node --version
pnpm --version
pi --version
test -L ~/.config/uv/uv.toml && readlink ~/.config/uv/uv.toml
uv python list --only-installed
openai --version
# Apple/Xcode Python remains available, but its user scripts are not global.
/usr/bin/python3 --version
zsh -lc '[[ ":$PATH:" != *":$HOME/Library/Python/3.9/bin:"* ]]'
# A child process launched from this configured login shell inherits its PATH.
bash -c 'go version; node --version; pnpm --version; pi --version'
test -f ~/.dotfiles/config/zsh/prompts/purification/prompt_purification_setup
zsh -i -c 'echo $FZF_DEFAULT_COMMAND'
zsh -i -c 'echo $FZF_CTRL_T_COMMAND'
zsh -i -c 'typeset -f fcd ffcd fview fstack >/dev/null && echo ok'
zsh -i -c 'typeset -f prompt_purification_setup >/dev/null && echo ok'
# Plugins: each clone present, and each one actually loaded into the shell.
ls ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
zsh -i -c '[[ -n $widgets[fzf-tab-complete] ]] && echo fzf-tab ok'
# Run this directly in a terminal, without piping/capturing stdin or stdout:
zsh -i -c '[[ -n $widgets[fzf-history-widget] ]] && echo fzf-keybindings ok'
zsh -i -c 'typeset -f _zsh_autosuggest_start >/dev/null && echo autosuggestions ok'
zsh -i -c 'whence -w -- -fast-highlight-process >/dev/null && echo highlighting ok'
zsh -i -c 'typeset -f z >/dev/null && echo zoxide ok'
# Diff rendering.
test -L ~/.config/git/delta.gitconfig && readlink ~/.config/git/delta.gitconfig
git config --get core.pager
test -L ~/Library/Application\ Support/lazygit/config.yml
```

Completion uses plain `compinit`, including its ownership/permission audit even
when `.zcompdump` exists. If it reports insecure paths, inspect `compaudit` and
repair ownership/permissions rather than bypassing the audit. fzf's ZLE
integration (including legacy fallbacks) loads only with interactive ZLE,
terminal stdin/stdout, and a non-`dumb` terminal. Captured `zsh -i -c` commands
still get `FZF_*` defaults and helper functions, but not fzf key bindings.

Windows equivalents:

```powershell
Get-Content $HOME/.dotfiles/install/platforms/windows/winget-packages.txt | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { winget list --id $_ -e --accept-source-agreements }
wsl -l -q
```

Debian equivalents:

```bash
test -L ~/.bashrc && readlink ~/.bashrc
bash -n ~/.dotfiles/config/bash/.bashrc
sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages
```

Check `mise current` against `config/mise/config.toml` and confirm `core.pager`
is `delta`. `FZF_DEFAULT_COMMAND` should use `fd`, or Debian's `fdfind` when
`fd` is absent. On Windows, a WSL distro should appear in `wsl -l -q`; run the
Debian/Ubuntu bootstrap inside it. On Debian, an already-satisfied apt manifest
should skip package installation and the login shell should stay unchanged
without `--force-shell`. A missing plugin clone degrades interactive Zsh rather
than preventing startup; check the clone list if a widget is absent.

Smoke-test navigation helpers in an interactive shell:

```zsh
fcd
ffcd
fview
fstack
```

## Backup

Bootstrap moves a replaced file, directory, or incorrect symlink to a
collision-safe backup beside its original path:
`<original-path>.bak.<timestamp>[.N]`. For example, a replaced `~/.zshrc`
becomes `~/.zshrc.bak.<timestamp>[.N]`. Correct links produce no new backup.
Inspect the backups next to the path you intend to restore.

`~/.gitconfig` is edited in place rather than backed up: bootstrap only appends
one `include.path` entry with `git config --global --add`, and never rewrites
anything else in that file. Revert it with:

```zsh
git config --global --unset include.path "${XDG_CONFIG_HOME:-$HOME/.config}/git/delta.gitconfig"
```

## Restore

1. Remove current managed symlink.
2. Move chosen `*.bak.<timestamp>[.N]` back to original path.
3. Start a new shell.

Remove the current path only when it is the expected repo-owned link:

```zsh
expected="$HOME/.dotfiles/config/zsh/.zshrc"
if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$expected" ]]; then
  rm -- "$HOME/.zshrc"
  mv ~/.zshrc.bak.20260224010101 ~/.zshrc
  exec zsh
else
  echo "Refusing to remove ~/.zshrc: it is not the expected managed link" >&2
fi
```

Debian bash example:

```bash
expected="$HOME/.dotfiles/config/bash/.bashrc"
if [ -L "$HOME/.bashrc" ] && [ "$(readlink "$HOME/.bashrc")" = "$expected" ]; then
  rm -- "$HOME/.bashrc"
  mv ~/.bashrc.bak.20260224010101 ~/.bashrc
  exec bash
else
  echo "Refusing to remove ~/.bashrc: it is not the expected managed link" >&2
fi
```

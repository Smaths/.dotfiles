# Operations

## Install on a new machine

Start with the platform commands in the [Quick start](../README.md#quick-start).
Available bootstrap flags:

- `--dry-run`: print intended actions without mutating.
- `--yes`: run without interactive confirmation on macOS, Windows, and Debian.
- `--verbose`: show extra command detail.
- `--profile slim|full` (macOS only): choose the package profile; default
  `full`. See [package profiles and groups](#package-profiles-and-groups).
- `--with GROUPS` / `--without GROUPS` (macOS only): add or remove
  comma-separated package groups on top of the profile. `--with creative`
  replaces the retired `--creative` flag.
- `--macos-settings` (macOS only): apply the managed macOS defaults unattended
  after linking config.
- `--upgrade-packages` (macOS only): upgrade outdated entries in the selected
  groups during bootstrap.
- `--upgrade-plugins` (macOS and Debian): fast-forward existing Zsh plugin
  clones to the exact manifest pins, independently of package upgrades.
- `--skip-packages`: skip package installs (`brew bundle` on macOS, `winget`
  on Windows, `apt-get` on Debian). On macOS, `git` and `mise` must already be
  installed, and the flag cannot be combined with the package selection flags
  or `--upgrade-packages`. On Debian, `zsh` must already be installed, along
  with `git` unless `--skip-plugins` is also used.
- `--skip-plugins` (Debian only): skip plugin installs and updates; cannot be
  combined with `--upgrade-plugins`. Pass it with `--skip-packages` for an
  offline config-only install. Existing plugins are left in place and can
  still load at shell startup.
- Windows does not support native shell linking; the retired `--link-windows-shell` option is rejected. Use the Debian/Ubuntu bootstrap inside WSL.
- `--force-shell` (Debian only): make Zsh the current user's login shell via
  `chsh`, which may prompt for the user's password. Without this flag, start
  Zsh with `exec zsh -l` or leave the current shell in place.

Interactive runs ask before changes. Unattended installs require `--yes`;
use `--dry-run` to preview instead.

### Package profiles and groups

macOS packages live in `install/platforms/macos/packages/`, one Brewfile per
group. `packages/profiles` names the groups each profile installs:

| Group | Contents | `slim` | `full` |
| --- | --- | :-: | :-: |
| `core` (required) | Zsh, shell CLI tools, Git tools, mise, uv, Ghostty, Nerd Font | yes | yes |
| `dev` | Docker Desktop, GitHub Desktop, VS Code, Zed | yes | yes |
| `utilities` | pandoc, Keka, Hex | yes | yes |
| `ai` | ChatGPT, Claude, Claude Code, Codex, OpenAI CLI, OpenCode | | yes |
| `dev-extras` | Cloud CLIs, SDKs, MySQL 8.4, Herd, secondary editors and clients | | yes |
| `media` | ffmpeg, ImageMagick, Ghostscript, wimlib, ImageOptim, VLC | | yes |
| `network` | nmap, mosh, lftp, rsync, tcping | | yes |
| `desktop` | Alfred, BetterTouchTool, Rectangle, Shottr, iStat Menus, Obsidian, Chrome, and more | | yes |
| `personal` | 1Password, KeePassXC, ProtonVPN, LuLu, Synology Drive, Transmission | | yes |
| `creative` | Creative and audio apps, Unity Hub | | |

Compose a selection from a profile plus group changes:

```zsh
sh ~/.dotfiles/install/bootstrap.sh --profile slim --dry-run
sh ~/.dotfiles/install/bootstrap.sh --profile slim --with ai
sh ~/.dotfiles/install/bootstrap.sh --without personal,network
sh ~/.dotfiles/install/bootstrap.sh --with creative
```

To install one group without running the rest of bootstrap:

```zsh
brew bundle install --no-upgrade \
  --file ~/.dotfiles/install/platforms/macos/packages/creative.Brewfile
```

Shell aliases and integrations for tools outside the selection are skipped at
startup. To use your own package list instead, install it yourself and run
bootstrap with `--skip-packages`; `git` and `mise` must already be installed.

Ableton Live remains vendor-managed. The `creative` group installs Unity Hub,
not Homebrew's rolling `unity` editor; use each project's
`ProjectSettings/ProjectVersion.txt` to select an editor in Hub or Unity CLI.
`brew bundle cleanup` against one group file treats every other group's
packages as unlisted. Preview cleanup against all the groups you use before
considering `--force`.

### macOS settings

Pass `--macos-settings` to bootstrap to apply the managed defaults unattended,
or run the script yourself:

```zsh
zsh ~/.dotfiles/install/platforms/macos/settings.zsh
zsh ~/.dotfiles/install/platforms/macos/settings.zsh --yes --dry-run
```

Interactive runs offer three modes:

- `1) Use defaults (no per-setting prompts)`: applies repo defaults after confirmation.
- `2) Choose settings`: set defaults for each setting, then proceed.
- `3) Skip`: exits macOS tuning without applying defaults.

`--yes` applies the defaults without prompts; `--dry-run` prints the
`defaults` commands instead. Settings are user-level `defaults write` calls, so
an employer's configuration profile may override some of them. Turning off
natural scrolling may need a log out. Set Caps Lock -> Control once in System
Settings > Keyboard > Keyboard Shortcuts > Modifier Keys; it is not scripted
because macOS stores it per keyboard and `hidutil` remaps reset at reboot.

Alfred workflow and theme files require manual import. See
[Alfred setup](ALFRED.md) for the package command, vault setting, and import
precautions. Rectangle preferences also require manual import; see
[Rectangle setup](RECTANGLE.md) for shortcuts, permissions, native tiling, and
Voyager modifiers.

## Update an existing machine

```zsh
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh
```

On macOS, bootstrap skips Brew Bundle when the selected packages are installed.
Otherwise it runs `brew bundle install --verbose --no-upgrade --jobs=auto` to
add missing entries without upgrading existing ones. Up to four formula installs
can run in parallel, so output may interleave. Brew Bundle and mise run in the
foreground with their normal output and signal handling.

The vendored Prompt Purification needs no separate install; both Zsh bootstraps
validate it before linking `.zshrc`. On macOS, bootstrap links
`config/mise/config.toml` at mise's standard XDG path, then runs `mise install`
for the tools and versions in that file. Project mise files, `.nvmrc`,
`.node-version`, and `packageManager`
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

`config/mise/config.toml` tracks `latest` for Go, Node.js, and pnpm and `1.5`
for Pi. Pi stays on the 1.5 release series until you change the selector. A
Homebrew upgrade does not update mise-managed versions; use mise to check for
and apply updates:

```zsh
mise outdated
mise upgrade
```

`latest` follows each tool's newest release line, including odd-numbered
Node.js releases that never become LTS. Projects that need a specific version
keep declaring it in their own mise config, `.nvmrc`, `.node-version`,
`packageManager`, or `go.mod`, and those declarations take precedence.

Pi is installed as a standalone executable, so `pi update` cannot replace the
executable and may report its internal Bun path (`/$bunfs/root/pi`). Use
`mise upgrade pi` instead, and `pi update --extensions` only to update
configured Pi extensions.

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

```sh
cd ~/.dotfiles
git pull --ff-only
sh install/bootstrap.sh
```

If switching an existing Bash setup to Zsh, add `--force-shell` to change the
login shell. Bootstrap leaves `~/.bashrc`, `~/.profile`, and Bash history in
place; move the customizations you still want to `config/zsh/local.zsh` in Zsh
syntax rather than sourcing Bash's startup files.

Without `--skip-packages`, Debian bootstrap checks `install/platforms/debian/apt-packages.txt`
first and skips `apt-get update`/`apt-get install` when every manifest package
is already installed, including packages on hold. If packages are missing,
it refreshes apt metadata and asks apt to install the missing names without
removing other packages. With `--yes`, package configuration uses debconf's
noninteractive mode.
`sudo` may still ask for authentication; an unattended run needs root or
sudo authorization that doesn't require a prompt.

## Health checks

Run `bash tests/check.sh` for static and helper checks, including Rectangle JSON
schema validation with `jq` (installed by the macOS `core` group). CI also verifies a
pinned `shfmt` binary because Ubuntu's package cannot parse this repo's Zsh.
CI runs `tests/install/debian_smoke_test.sh` as root in disposable Docker
containers to check real apt and plugin installs, backups, Zsh and tmux
startup, opt-in login-shell changes, and idempotent reruns. Docker is not
required for bootstrap.

On an installed machine, check the relevant paths and tools:

```zsh
test -L ~/.zshrc && readlink ~/.zshrc
test -L ~/.zprofile && readlink ~/.zprofile
sh ~/.dotfiles/install/bootstrap.sh --dry-run --profile slim  # or your profile
test -L ~/.config/mise/config.toml && readlink ~/.config/mise/config.toml
mise current
go version
node --version
pnpm --version
pi --version
test -L ~/.config/uv/uv.toml && readlink ~/.config/uv/uv.toml
uv python list --only-installed
openai --version  # ai group
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
zsh -i -c 'whence -w z >/dev/null && echo zoxide ok'
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
Older Debian/Ubuntu fzf packages ship the key bindings in
`/usr/share/doc/fzf/examples`; stripped images without those files still get
fzf helpers and fzf-tab, but not the built-in fzf key bindings.

Windows equivalents:

```powershell
Get-Content $HOME/.dotfiles/install/platforms/windows/winget-packages.txt | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { winget list --id $_ -e --accept-source-agreements }
wsl -l -q
```

Debian equivalents:

```sh
test -L "${ZDOTDIR:-$HOME}/.zshrc" && readlink "${ZDOTDIR:-$HOME}/.zshrc"
test -L "${ZDOTDIR:-$HOME}/.zprofile" && readlink "${ZDOTDIR:-$HOME}/.zprofile"
zsh -lic 'echo "$FZF_DEFAULT_COMMAND"; alias ll'
getent passwd "$(id -un)" | cut -d: -f7    # account login shell
sh ~/.dotfiles/install/bootstrap.sh --dry-run --skip-packages
```

`FZF_DEFAULT_COMMAND` should use `fd`, or Debian's `fdfind` when `fd` is absent.
An already-satisfied apt manifest should skip package installation and the
login shell should stay unchanged without `--force-shell`. A missing plugin
clone degrades interactive Zsh rather than preventing startup; check the clone
list if a widget is absent. On Windows, a WSL distro should appear in `wsl -l -q`;
run the Debian/Ubuntu bootstrap inside it.

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

On Debian, also check `.zprofile` and use your custom `ZDOTDIR` instead of
`$HOME` when restoring files there. If you changed your login shell with
`--force-shell`, switch back with
`chsh -s /bin/bash` (or specify your previous shell), then start a new login
session. Bootstrap did not remove or replace Bash startup files.

# Dotfiles

Personal dotfiles for a reproducible development shell and workstation setup, centered on macOS with a Windows host-app bootstrap and a Debian/Ubuntu WSL or server shell setup.

## Supported platforms

| Platform | Support | Entry point | Scope |
| --- | --- | --- | --- |
| macOS 14+ | Primary | `install/bootstrap.sh` | Core workstation packages, Zsh config and runtimes |
| Windows | Secondary | `install/bootstrap.ps1` | Windows host applications via winget; shell setup is in WSL |
| Debian / Ubuntu LTS | Secondary | `install/bootstrap.sh` | CLI packages and Bash/tmux config on servers or WSL |
| Other Linux | Config reuse only | None | No generic bootstrap |

See [platform details](docs/PLATFORMS.md).

## Quick start

macOS (full personal machine):

```sh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

macOS baseline, such as a work machine, with the managed macOS settings:

```sh
sh ~/.dotfiles/install/bootstrap.sh --profile slim --macos-settings
```

See [package profiles and groups](docs/OPERATIONS.md#package-profiles-and-groups)
for `--with`/`--without`.

Windows PowerShell (review the scripts before running):

```powershell
git clone https://github.com/Smaths/.dotfiles.git $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap.ps1
```

On a Debian or Ubuntu server, or inside Debian or Ubuntu on WSL, run this as the
user whose shell you want to configure. On WSL, clone inside the Linux filesystem
(not `/mnt/c`). Bootstrap uses `sudo` only for apt if needed:

```sh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh --dry-run
sh ~/.dotfiles/install/bootstrap.sh
```

Use `--skip-packages` to link Bash and tmux config without needing apt or `sudo`.

## Safety defaults

Use `--dry-run` to see what bootstrap would do. Interactive runs ask before
making changes: macOS and Debian show a preflight plan, and Windows shows the
missing winget IDs. Unattended installs require `--yes`.

- **Your files:** Existing shell config files are backed up before being
  replaced; correct symlinks are left alone. Backups get unique timestamps on
  repeated runs.
- **Updates:** Bootstrap doesn't run a general package upgrade. macOS package
  upgrades need `--upgrade-packages`; Windows installs only missing exact IDs.
  Debian/Ubuntu installs missing manifest packages and lets apt resolve dependencies.
  Zsh plugins are pinned to commits with verified origins and advance only with
  `--upgrade-plugins`, not package upgrades. See [pin review](docs/OPERATIONS.md#plugin-pin-review).
- **System settings:** macOS settings are optional: run `settings.zsh` or pass
  `--macos-settings` to bootstrap.
  Debian's login shell changes only with `--force-shell`.
- **Removal:** There is no uninstall command. Only remove links or references
  after confirming this repo owns them. Review package removals individually,
  and preview the effect before deleting a regular config file or running broad
  package cleanup. See [backup and restore](docs/OPERATIONS.md#backup).

## Managed scope

macOS is the main workstation setup. Windows bootstrap installs host apps only;
Debian/Ubuntu handles Bash and tmux in WSL or on a server.

<details>
<summary>What gets installed or linked</summary>

- **Packages:** macOS installs package groups from
  `install/platforms/macos/packages/`: the `full` profile by default, `slim`
  for a baseline machine, and `creative` only with `--with creative`. Windows host apps come from
  `install/platforms/windows/winget-packages.txt`; Debian CLI packages come from
  `install/platforms/debian/apt-packages.txt`.
- **Shell and app config:** macOS links Zsh, tmux, Ghostty, Git delta/lazygit,
  mise, and uv config. Debian links `~/.bashrc` and optionally tmux config.
  Windows does not link native Zsh files. The only `~/.gitconfig` change is a
  single delta `include.path` entry.
- **Tool ownership:** mise supplies the Go, Node.js, Pi, and pnpm versions in
  `config/mise/config.toml`; project declarations can override them. Its shims
  are on the managed Zsh login PATH, not automatically available to GUI or other
  non-shell processes. uv manages Python interpreters and environments; Homebrew owns
  native standalone apps. Project libraries belong in project manifests and
  lockfiles, not shared user-level environments.
- **Manual and local config:** Keep machine-specific Zsh settings in ignored
  `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`, not tracked modules.
  Alfred workflow and theme copies in `config/alfred/` need manual import; see
  [Alfred setup](docs/ALFRED.md). Rectangle preferences in `config/rectangle/`
  also need manual import; see [window snapping setup](docs/RECTANGLE.md).

</details>

See [Operations](docs/OPERATIONS.md) for update, rollback, and check commands.
[Architecture](docs/ARCHITECTURE.md) covers file ownership and linking. See
also [Contributing](CONTRIBUTING.md) and [Security](SECURITY.md).

## Validation

Run the repository's static and shared-helper checks:

```sh
bash tests/check.sh
```

Platform-specific verification commands and CI coverage are documented in [Operations](docs/OPERATIONS.md#health-checks).

# Dotfiles

Personal dotfiles for a reproducible development shell and workstation setup, centered on macOS with a Windows host-app bootstrap and a Debian/Ubuntu WSL or server shell setup.

## Supported platforms

| Platform | Support | Entry point | Scope |
| --- | --- | --- | --- |
| macOS 14+ | Primary | `install/bootstrap.sh` | Core workstation packages, Zsh config and runtimes |
| Windows | Secondary | `install/bootstrap.ps1` | Windows host applications via winget; shell setup is in WSL |
| Debian stable / Debian-like | Secondary | `install/bootstrap.sh` | CLI packages and Bash/tmux config |
| Other Linux | Config reuse only | None | No generic bootstrap |

See [platform details](docs/PLATFORMS.md).

## Quick start

macOS:

```sh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh
```

Windows PowerShell (review the scripts before running):

```powershell
git clone https://github.com/Smaths/.dotfiles.git $HOME/.dotfiles
powershell -ExecutionPolicy Bypass -File $HOME/.dotfiles/install/bootstrap.ps1
```

For Windows shell tools, install/use Debian or Ubuntu in WSL, clone the repo inside the Linux filesystem (not `/mnt/c`), then run the Unix commands below. For a Debian server:

```sh
git clone https://github.com/Smaths/.dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install/bootstrap.sh --dry-run
sh ~/.dotfiles/install/bootstrap.sh
```

## Safety defaults

Use `--dry-run` to see what bootstrap would do. Interactive runs ask before
making changes: macOS and Debian show a preflight plan, and Windows shows the
missing winget IDs. Unattended installs require `--yes`.

- **Your files:** Existing shell config files are backed up before being
  replaced; correct symlinks are left alone. Backups get unique timestamps on
  repeated runs.
- **Updates:** Packages are added without upgrades by default. macOS package
  upgrades need `--upgrade-packages`; Windows installs only missing exact IDs.
  Zsh plugins are pinned to commits with verified origins and advance only with
  `--upgrade-plugins`, not package upgrades. See [pin review](docs/OPERATIONS.md#plugin-pin-review).
- **System settings:** macOS settings are optional and separate from bootstrap.
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

- **Packages:** macOS uses `install/platforms/macos/Brewfile`; `--creative` adds
  `Brewfile.creative` only when requested. Windows host apps come from
  `install/platforms/windows/winget-packages.txt`; Debian CLI packages come from
  `install/platforms/debian/apt-packages.txt`.
- **Shell and app config:** macOS links Zsh, tmux, Ghostty, Git delta/lazygit,
  mise, and uv config. Debian links `~/.bashrc` and optionally tmux config.
  Windows does not link native Zsh files. The only `~/.gitconfig` change is a
  single delta `include.path` entry.
- **Tool ownership:** mise defaults to Go 1.27, Node.js 24, Pi, and pnpm 11;
  project declarations can select other tools. Its shims are on the managed
  Zsh login PATH, not automatically available to GUI or other non-shell
  processes. uv manages Python interpreters and environments; Homebrew owns
  native standalone apps. Project libraries belong in project manifests and
  lockfiles, not shared user-level environments.
- **Manual and local config:** Keep machine-specific Zsh settings in ignored
  `config/zsh/local.zsh` or `config/zsh/local.d/*.zsh`, not tracked modules.
  Alfred workflow and theme copies in `config/alfred/` need manual import; see
  [Alfred setup](docs/ALFRED.md).

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

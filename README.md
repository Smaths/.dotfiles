# Dotfiles

Personal dotfiles for a reproducible development shell and workstation setup, centered on macOS with a Windows host-app bootstrap and a Debian/Ubuntu WSL or server shell setup.

## Supported platforms

| Platform | Support | Entry point | Scope |
| --- | --- | --- | --- |
| macOS 14+ | Primary | `install/bootstrap.sh` | Core workstation packages, Zsh config and runtimes |
| Windows | Secondary | `install/bootstrap.ps1` | Windows host applications via winget; shell setup is in WSL |
| Debian stable / Debian-like | Secondary | `install/bootstrap.sh` | CLI packages and Bash/tmux config |
| Other Linux | Config reuse only | — | No generic bootstrap |

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

- Inspect a plan with `--dry-run`. macOS and Debian interactive runs show a preflight plan and ask before mutation; non-interactive mutation requires `--yes`. Windows shows missing winget IDs and asks before installing; `--yes` confirms noninteractive installs.
- Reruns converge. Existing shell config paths are backed up with collision-safe timestamps before replacement; correct symlinks remain unchanged.
- Package installs add missing entries without upgrading by default. macOS upgrades require `--upgrade-packages`; Windows installs only missing exact package IDs.
- Zsh plugins use exact commit pins and verified origins. Updating existing clones requires `--upgrade-plugins`, separately from package upgrades (see [pin review](docs/OPERATIONS.md#plugin-pin-review)).
- macOS system settings are a separate optional operation. Debian's login shell stays unchanged unless `--force-shell` is passed.
- No uninstall/cleanup command is provided. Remove only verified repo-owned links or references; inspect and select package removals individually. Never remove a regular config file or run broad package cleanup without previewing its full effect. See [backup and restore guidance](docs/OPERATIONS.md#backup).

## Managed scope

- macOS core package manifest: `install/platforms/macos/Brewfile`. Pass `--creative` to macOS bootstrap to additionally install `Brewfile.creative`; it is otherwise skipped.
- Windows manifest: host applications only in `install/platforms/windows/winget-packages.txt`. The bootstrap does not link native Windows Zsh files. WSL Debian/Ubuntu uses the Debian Bash/tmux bootstrap.
- Debian manifest: CLI packages in `install/platforms/debian/apt-packages.txt`, with `~/.bashrc` and optional tmux config.
- macOS shell setup links Zsh, tmux, Ghostty, Git delta/lazygit configs, mise config and uv config. The only permitted `~/.gitconfig` change is one delta `include.path` entry.
- mise defaults are Go 1.27, Node.js 24, Pi, and pnpm 11; project-local version declarations/configs select project tools. mise shims are added by the managed Zsh login PATH, not automatically inherited by every GUI or non-shell process.
- Python interpreters and Python environments are uv-managed; native standalone applications are owned by Homebrew. Project libraries belong to project manifests/lockfiles, not shared user-level environments.
- Machine-specific Zsh overrides belong in ignored `config/zsh/local.zsh` and `config/zsh/local.d/*.zsh`, not tracked shared modules.

Detailed commands, updates, rollback, and checks live in [Operations](docs/OPERATIONS.md). Ownership and design are in [Architecture](docs/ARCHITECTURE.md). See also [Contributing](CONTRIBUTING.md), [LLM guidance](docs/LLM.md), and [Security](SECURITY.md).

## Validation

Run the repository's static and shared-helper checks:

```sh
bash tests/check.sh
```

Platform-specific verification commands and CI coverage are documented in [Operations](docs/OPERATIONS.md#doctor-health-checks).

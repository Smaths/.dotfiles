# Platform Notes

## macOS (Primary)

Supported target: macOS 14+.

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/macos/bootstrap.zsh`, which installs Homebrew if missing.
- Installs missing core workstation entries from
  `install/platforms/macos/Brewfile` without upgrading existing packages by
  default.
- Installs the specialist creative/audio cask set in
  `install/platforms/macos/Brewfile.creative` only when `--creative` is passed;
  it is skipped by default. Ableton Live is deliberately vendor-managed rather
  than declared in either manifest. Unity Hub is optional, and exact editor
  versions are managed through Hub or the Unity CLI rather than Homebrew's
  rolling `unity` cask.
- Runs Homebrew, Brew Bundle, and mise installation commands in the foreground
  with native output and signal handling.
- Downloads the official Homebrew installer to a temporary file before running
  it so the installer retains terminal input for confirmation and `sudo`
  prompts, then removes the temporary file.
- Uses Homebrew-installed `mise` to install the pinned Go and Node.js runtimes,
  Pi terminal agent, and pnpm 11 default from `config/mise/config.toml`.
  Project version files and pnpm `packageManager` metadata remain the source of
  truth for project overrides.
- Homebrew owns native applications and standalone CLIs; mise owns the declared
  Go, Node.js, Pi, and pnpm tools; uv owns Python interpreters and environments.
  Bootstrap links `config/uv/uv.toml` and does not modify Apple/Xcode Python.
  Project dependencies belong to each project's manifests and lockfiles.
- Loads Prompt Purification from the vendored Zsh source in this repository;
  bootstrap performs no prompt-specific download and validates the source
  before linking `~/.zshrc`.
- Clones the Zsh plugins listed in `install/lib/zsh-plugins.sh` into
  `${XDG_DATA_HOME:-~/.local/share}/zsh/plugins`. Missing plugins are cloned on
  every run; existing clones are fast-forwarded only under
  `--upgrade-packages`. This is the one place bootstrap fetches source outside
  Homebrew, mise, and uv.
- Links `config/git/delta.gitconfig` and adds a single `include.path` entry to
  the otherwise unmanaged `~/.gitconfig`, and links `config/lazygit/config.yml`
  into lazygit's config directory.
- Machine/project-only Zsh overrides belong in ignored `config/zsh/local.zsh`
  or `config/zsh/local.d/*.zsh`, not tracked shared modules.
- Uses MySQL 8.4 LTS through the keg-only `mysql@8.4` formula; Zsh adds its
  client and server binaries to `PATH`. Bootstrap installs or verifies the
  formula but leaves the Homebrew service state unchanged.
- Pass `--upgrade-packages` to intentionally upgrade outdated Brewfile entries
  during bootstrap.
- Keeps interactive system defaults separate from bootstrap; run them explicitly
  with `zsh ~/.dotfiles/install/platforms/macos/settings.zsh`.

## Windows (Secondary, Host Applications + WSL)

Windows bootstrap manages Windows-host applications only. Shell setup is performed in Debian or Ubuntu under WSL, using the Debian Bash/tmux bootstrap.

Prerequisites:

- PowerShell 5.1+ or PowerShell 7+.
- `winget` for host-app installation from `install/platforms/windows/winget-packages.txt`; pass `--skip-packages` to continue without winget/package installs.

Behavior:

- `install/bootstrap.ps1` dispatches to `install/platforms/windows/bootstrap.ps1`, which validates the Windows runtime.
- Validates manifest IDs, checks installed state by exact ID, prints the missing host-app plan, then asks for confirmation. Use `--yes` to confirm noninteractive installation; `--dry-run` makes no changes.
- Does not create, replace, or remove native Windows Zsh links. `--link-windows-shell` is rejected.
- Provides WSL guidance. Clone the repo inside the Linux filesystem (not `/mnt/c`) and run `sh ~/.dotfiles/install/bootstrap.sh` there. Debian/Ubuntu WSL uses the Debian Bash/tmux setup, not Windows-host Zsh.
- Windows bootstrap does not manage language runtimes, project modules, or WSL packages; those belong to the corresponding Linux setup/project. Winget does not track bootstrap ownership, so uninstall apps only after individually reviewing the IDs.

## Debian Server (Secondary)

Debian server bootstrap is available for bash-first, CLI-only server setup.

Supported target: Debian stable or Debian-like systems with `apt-get`.

Prerequisites:

- `bash`, `apt-get`, and core GNU userland.
- Root access for package installation, either directly or through `sudo`.
- Internet access for apt repositories when package installation is enabled.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/debian/bootstrap.sh`, which validates the platform before mutation.
- Installs missing packages from `install/platforms/debian/apt-packages.txt` unless `--skip-packages` is passed.
- Skips `apt-get update` and `apt-get install` when all manifest packages are already installed.
- Links `~/.bashrc` to `config/bash/.bashrc` after backing up an existing file.
- Keeps the current login shell unchanged unless `--force-shell` is passed.
- Does not install GUI packages or apply desktop settings.

## Other Linux (Config Reuse Only)

Other Linux distributions are not first-class bootstrap targets in this repo today.

- `install/bootstrap.sh` exits on unsupported Linux distributions.
- `install/platforms/debian/bootstrap.sh` is intended for Debian and Debian-like systems only.
- You can still reuse parts of `config/zsh/` or `config/bash/` manually.
- Generic package and desktop automation are not implemented for Linux here.

## Cross-Platform Caveats

- Network operations are limited to `brew`, `mise`, `uv`, `winget`, `apt-get`,
  `git`, and `curl`; package ownership is platform-specific as described above.
- Uninstall is manual and preview-first: remove only verified repository-owned
  links/config references, preserve regular user files, inspect backups before
  restoring, and review package removals individually. Never use broad cleanup
  as an assumed inverse of bootstrap.
- Shared Zsh aliases stay macOS/general-development focused; machine- and
  project-specific commands belong in ignored local modules.
- Debian bash config intentionally keeps aliases server-safe and minimal.
- Homebrew paths differ by architecture (`/opt/homebrew` vs `/usr/local`).
- GUI app casks in `install/platforms/macos/Brewfile` are macOS-specific.

## Future Expansion

If support expands beyond Debian, keep each platform in a separate explicit
entrypoint rather than weakening current macOS guarantees.

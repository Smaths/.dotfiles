# Platform notes

## macOS (primary)

Supported target: macOS 14+.

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/macos/bootstrap.zsh`, which installs Homebrew if missing.
- Installs missing core workstation entries from
  `install/platforms/macos/Brewfile` without upgrading existing packages by
  default.
- Adds `install/platforms/macos/Brewfile.creative` only with `--creative`.
  Ableton Live stays vendor-managed; Unity Hub installs through that optional
  manifest, while project-specific editor versions come from Hub or Unity CLI.
- Runs Homebrew, Brew Bundle, and mise in the foreground. The Homebrew installer
  runs from a temporary file so confirmation and `sudo` prompts work.
- Installs Go, Node.js, Pi, and pnpm via Homebrew-installed mise. Project
  version files and `packageManager` metadata can override defaults.
- Links `config/uv/uv.toml` for uv-managed Python; Apple/Xcode Python stays
  untouched. Homebrew owns native apps, mise owns declared tools, and project
  dependencies stay in project manifests.
- Loads Prompt Purification from the vendored Zsh source in this repository;
  bootstrap performs no prompt-specific download and validates the source
  before linking `~/.zshrc`.
- Installs missing Zsh plugins at exact commit pins. Existing clones are
  checked for origin and cleanliness, then advanced only with
  `--upgrade-plugins`, not `--upgrade-packages`. See [plugin updates](OPERATIONS.md#plugin-pin-review).
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
- Leaves Alfred workflow and theme imports to the user. See [Alfred setup](ALFRED.md).

## Windows (secondary, host applications and WSL)

Windows bootstrap manages Windows-host applications only. Shell setup is performed in Debian or Ubuntu under WSL, using the Debian Bash/tmux bootstrap.

Prerequisites:

- PowerShell 5.1+ or PowerShell 7+.
- `winget` for host-app installation from `install/platforms/windows/winget-packages.txt`; pass `--skip-packages` to continue without winget/package installs.

Behavior:

- `install/bootstrap.ps1` dispatches to `install/platforms/windows/bootstrap.ps1`, which validates the Windows runtime.
- Validates manifest IDs and checks installed apps by exact ID. It prints the
  missing host-app plan and asks for confirmation. Use `--yes` for a
  noninteractive install; `--dry-run` makes no changes.
- Does not create, replace, or remove native Windows Zsh links. `--link-windows-shell` is rejected.
- Explains WSL setup. Clone the repo inside the Linux filesystem, not `/mnt/c`,
  and run `sh ~/.dotfiles/install/bootstrap.sh` there. Debian/Ubuntu in WSL
  uses the Debian Bash/tmux setup, not Windows-host Zsh.
- Windows bootstrap does not manage language runtimes, project modules, or
  WSL packages. Manage those in the Linux setup or project. Winget does not
  track bootstrap ownership, so review each package ID before uninstalling.

## Debian server (secondary)

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

## Other Linux (config reuse only)

`install/bootstrap.sh` exits on unsupported distributions. You can reuse
`config/zsh/` or `config/bash/` manually, but there is no generic Linux package
or desktop bootstrap.

## Cross-platform caveats

- Uninstall is manual: verify repo-owned links, preserve regular user files,
  inspect backups, and review package removals individually. See
  [backup and restore](OPERATIONS.md#backup).
- Shared Zsh aliases target macOS/general development; Debian Bash keeps a
  minimal server-safe set. Put machine-specific commands in ignored local modules.
- Homebrew paths vary by architecture (`/opt/homebrew` or `/usr/local`); macOS
  casks do not apply to other platforms.

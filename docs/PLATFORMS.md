# Platform notes

## macOS (primary)

Supported target: macOS 14+.

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/macos/bootstrap.zsh`, which installs Homebrew if missing.
- Installs missing entries from the package groups of the selected profile
  (`--profile slim|full`, default `full`) in `install/platforms/macos/packages/`,
  without upgrading existing packages by default. `--with` and `--without`
  adjust the groups; `--skip-packages` installs none, and then `git` and `mise`
  must already be installed.
- Installs the `creative` group only with `--with creative`. Ableton Live stays
  vendor-managed; Unity Hub installs through that group, while
  project-specific editor versions come from Hub or Unity CLI.
- Runs Homebrew, Brew Bundle, and mise in the foreground. The Homebrew installer
  runs from a temporary file so confirmation and `sudo` prompts work.
- Installs Go, Node.js, and pnpm on `latest` and Pi on `1.5` via
  Homebrew-installed mise. `mise upgrade` updates within those selections.
  Project version files and `packageManager` metadata can override defaults.
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
- Uses MySQL 8.4 LTS through the keg-only `mysql@8.4` formula in the
  `dev-extras` group; when installed, Zsh adds its
  client and server binaries to `PATH`. Bootstrap installs or verifies the
  formula but leaves the Homebrew service state unchanged.
- Pass `--upgrade-packages` to intentionally upgrade outdated entries in the
  selected groups during bootstrap.
- Applies macOS defaults (Finder, Dock, trackpad) only when asked: pass
  `--macos-settings` to bootstrap, or run
  `zsh ~/.dotfiles/install/platforms/macos/settings.zsh` interactively. Caps
  Lock -> Control is a manual System Settings step.
- Leaves Alfred workflow and theme imports to the user. See [Alfred setup](ALFRED.md).

## Windows (secondary, host applications and WSL)

Windows bootstrap manages Windows-host applications only. Shell setup is performed in Debian or Ubuntu under WSL, using the Debian Zsh/tmux bootstrap.

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
  uses the Debian Zsh/tmux setup, not Windows-host Zsh.
- Windows bootstrap does not manage language runtimes, project modules, or
  WSL packages. Manage those in the Linux setup or project. Winget does not
  track bootstrap ownership, so review each package ID before uninstalling.

## Debian and Ubuntu (secondary)

Slim development setup for servers and WSL: Zsh, tmux, and Pi via mise.
CI tests Debian 12 and 13 and Ubuntu 22.04, 24.04, and 26.04 LTS. Other Debian
derivatives are not tested.

Prerequisites:

- Bash and the standard GNU userland to run bootstrap. Git and GitHub access
  are needed to clone the repo and sync pinned Zsh plugins.
- For packages: apt, working distro repositories (including Universe on
  Ubuntu), and root or an existing `sudo` setup. No third-party apt repositories
  are added. Mise and Pi downloads also require internet access.
- Run as the user whose config you want to link, not with `sudo sh`. Use
  `--skip-packages --skip-plugins` to link config offline with Zsh already
  installed.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/debian/bootstrap.sh`,
  using the checkout that contains the script.
- Apt installs only missing manifest entries and their dependencies. When the
  manifest is already satisfied, bootstrap does not refresh apt metadata.
- Reuses existing `mise` or installs it under `~/.local/bin` using the official
  HTTPS installer at `https://mise.run`, without `sudo`. Mise installs Pi's
  latest standalone release. The Pi default lives in a `conf.d` fragment under
  mise's global config directory, so an existing `config.toml` stays untouched.
  Use `--skip-mise` to skip this step, including if you use a
  `MISE_GLOBAL_CONFIG_FILE` override. `--skip-packages` also skips it.
- Links the shared `.zshrc` and `.zprofile` into the absolute `ZDOTDIR` in
  bootstrap's environment, or `$HOME` if unset. Empty or relative values are
  rejected. If `.zshenv` sets a custom
  directory that the invoking shell doesn't export, pass it explicitly, e.g.
  `ZDOTDIR="$HOME/.config/zsh" sh ~/.dotfiles/install/bootstrap.sh`.
  Bootstrap doesn't modify `.zshenv` or set `ZDOTDIR` for future sessions.
- Links `~/.tmux.conf`. Existing configs at linked paths are backed up; Bash
  files (including old bootstrap links) stay untouched. Port wanted Bash-only
  customizations to `config/zsh/local.zsh` using Zsh syntax.
- Uses the same vendored prompt, aliases, and pinned plugins as macOS.
  Debian/Ubuntu's `fdfind` and `batcat` names are handled by the shared Zsh config.
- Leaves the login shell alone unless you pass `--force-shell`. After changing
  it, start a new login session (reconnect over SSH or reopen WSL). Use
  `exec zsh -l` to start Zsh immediately without waiting for a new session.
- Does not install Go, Node.js, pnpm, or uv, or apply desktop settings.

## Other Linux (config reuse only)

`install/bootstrap.sh` exits on unsupported distributions. You can reuse
`config/zsh/` or `config/bash/` manually, but there is no generic Linux package
or desktop bootstrap.

## Cross-platform caveats

- Uninstall is manual: verify repo-owned links, preserve regular user files,
  inspect backups, and review package removals individually. See
  [backup and restore](OPERATIONS.md#backup).
- Zsh loads aliases and integrations for tools that are installed. Put
  machine-specific commands in ignored local modules.
- Homebrew paths vary by architecture (`/opt/homebrew` or `/usr/local`); macOS
  casks do not apply to other platforms.

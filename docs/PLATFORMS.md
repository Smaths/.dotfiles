# Platform Notes

## macOS (Primary)

Supported target: macOS 14+.

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/macos/bootstrap.zsh`, which installs Homebrew if missing.
- Installs missing entries from `install/platforms/macos/Brewfile` without upgrading existing packages by default.
- Runs Homebrew, Brew Bundle, and mise installation commands in the foreground
  with native output and signal handling.
- Downloads the official Homebrew installer to a temporary file before running
  it so the installer retains terminal input for confirmation and `sudo`
  prompts, then removes the temporary file.
- Uses Homebrew-installed `mise` to install the pinned Node.js versions, Pi
  terminal agent, and pnpm 11 default from `config/mise/config.toml`. Project
  version files and pnpm `packageManager` metadata remain the source of truth
  for project overrides.
- Uses Homebrew-installed `uv` as the sole Python environment and package-tool
  manager. Bootstrap links `config/uv/uv.toml` and does not modify Apple/Xcode
  Python. Standalone native CLIs, including the official OpenAI CLI, remain
  Homebrew-owned.
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
- Uses MySQL 8.4 LTS through the keg-only `mysql@8.4` formula; Zsh adds its
  client and server binaries to `PATH`. Bootstrap installs or verifies the
  formula but leaves the Homebrew service state unchanged.
- Pass `--upgrade-packages` to intentionally upgrade outdated Brewfile entries
  during bootstrap.
- Keeps interactive system defaults separate from bootstrap; run them explicitly
  with `zsh ~/.dotfiles/install/platforms/macos/settings.zsh`.

## Windows (Secondary, WSL-First)

Windows bootstrap is available for optional winget package installs and WSL-first shell setup guidance.

Prerequisites:

- PowerShell 5.1+ or PowerShell 7+.
- Symlink permissions (Developer Mode enabled, or elevated shell).
- `winget` available for package automation from `install/platforms/windows/winget-packages.txt`.

Behavior:

- `install/bootstrap.ps1` dispatches to `install/platforms/windows/bootstrap.ps1`, which validates Windows runtime.
- Uses `install/platforms/windows/winget-packages.txt` when `winget` is available.
- Includes `Microsoft.WSL` and `Microsoft.WindowsTerminal` in the winget package set.
- Validates winget package IDs before mutation.
- Validates symlink capability only when `--link-windows-shell` is used.
- Prints recommended WSL commands to install `zsh`, `tmux`, `ripgrep`, and `fzf`, then link shell files in WSL.
- The linked Zsh config loads the same vendored Prompt Purification source as
  macOS; Windows does not download a separate prompt copy.
- Windows bootstrap does not clone the Zsh plugins. `config/zsh/plugins.zsh`
  skips missing plugins, so a linked Windows or WSL shell still starts; clone
  them manually under `${XDG_DATA_HOME:-~/.local/share}/zsh/plugins` if wanted.
- Skips Windows-host `~/.zshrc` and `~/.zprofile` links by default; enable with `--link-windows-shell`.
- If `winget` is missing, package installation is skipped (non-destructive default).
- Known scope gap: the preflight plan, confirmation prompt, and `--yes` flag are
  implemented for the Unix bootstraps only. The Windows bootstrap still relies on
  `--dry-run` for inspection and does not prompt before mutating. It also does not
  manage Node.js, Pi, or pnpm; `config/mise/config.toml` is macOS-only today.

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

- Zsh aliases include legacy Linux-centric helpers (pacman/yay/system commands).
- Debian bash config intentionally keeps aliases server-safe and minimal.
- Homebrew paths differ by architecture (`/opt/homebrew` vs `/usr/local`).
- GUI app casks in `install/platforms/macos/Brewfile` are macOS-specific.

## Future Expansion

If support expands beyond Debian, keep each platform in a separate explicit
entrypoint rather than weakening current macOS guarantees.

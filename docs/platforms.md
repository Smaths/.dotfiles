# Platform Notes

## macOS (Primary)

Supported target: modern macOS versions (13+).

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/bootstrap-macos.zsh`, which installs Homebrew if missing.
- Installs missing entries from `install/Brewfile` without upgrading existing packages by default.
- Pass `--upgrade-packages` to intentionally upgrade outdated Brewfile entries during bootstrap.
- Runs optional interactive system defaults via `install/platforms/macos.zsh`.

## Windows (Secondary, WSL-First)

Windows bootstrap is available for optional winget package installs and WSL-first shell setup guidance.

Prerequisites:

- PowerShell 5.1+ or PowerShell 7+.
- Symlink permissions (Developer Mode enabled, or elevated shell).
- `winget` available for package automation from `install/winget-packages.txt`.

Behavior:

- `install/bootstrap.ps1` dispatches to `install/platforms/bootstrap-windows.ps1`, which validates Windows runtime.
- Uses `install/winget-packages.txt` when `winget` is available.
- Includes `Microsoft.WSL` and `Microsoft.WindowsTerminal` in the winget package set.
- Validates winget package IDs before mutation.
- Validates symlink capability only when `--link-windows-shell` is used.
- Prints recommended WSL commands to install `zsh`, `tmux`, `ripgrep`, and `fzf`, then link shell files in WSL.
- Skips Windows-host `~/.zshrc` and `~/.zprofile` links by default; enable with `--link-windows-shell`.
- If `winget` is missing, package installation is skipped (non-destructive default).

## Debian Server (Secondary)

Debian server bootstrap is available for bash-first, CLI-only server setup.

Supported target: Debian stable or Debian-like systems with `apt-get`.

Prerequisites:

- `bash`, `apt-get`, and core GNU userland.
- Root access for package installation, either directly or through `sudo`.
- Internet access for apt repositories when package installation is enabled.

Behavior:

- `install/bootstrap.sh` dispatches to `install/platforms/bootstrap-debian.sh`, which validates the platform before mutation.
- Installs missing packages from `install/apt-packages.txt` unless `--skip-packages` is passed.
- Skips `apt-get update` and `apt-get install` when all manifest packages are already installed.
- Links `~/.bashrc` to `config/bash/.bashrc` after backing up an existing file.
- Keeps the current login shell unchanged unless `--force-shell` is passed.
- Does not install GUI packages or apply desktop settings.

## Other Linux (Config Reuse Only)

Other Linux distributions are not first-class bootstrap targets in this repo today.

- `install/bootstrap.sh` exits on unsupported Linux distributions.
- `install/platforms/bootstrap-debian.sh` is intended for Debian and Debian-like systems only.
- You can still reuse parts of `config/zsh/` or `config/bash/` manually.
- Generic package and desktop automation are not implemented for Linux here.

## Cross-Platform Caveats

- Zsh aliases include legacy Linux-centric helpers (pacman/yay/system commands).
- Debian bash config intentionally keeps aliases server-safe and minimal.
- Homebrew paths differ by architecture (`/opt/homebrew` vs `/usr/local`).
- GUI app casks in `install/Brewfile` are macOS-specific.

## Future Expansion

If support expands beyond Debian, keep each platform in a separate explicit
entrypoint rather than weakening current macOS guarantees.

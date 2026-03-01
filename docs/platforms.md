# Platform Notes

## macOS (Primary)

Supported target: modern macOS versions (13+).

Prerequisites:

- Xcode Command Line Tools (`xcode-select --install`) for `git`, `curl`, compilers.
- Internet access for Homebrew install and package downloads.

Behavior:

- `install/bootstrap.zsh` installs Homebrew if missing.
- Uses `brew bundle install --file=brew/Brewfile`.
- Runs optional interactive system defaults via `install/macos.zsh`.

## Windows (Secondary)

Windows bootstrap is available for config linking and optional winget package installs.

Prerequisites:

- PowerShell 5.1+ or PowerShell 7+.
- Symlink permissions (Developer Mode enabled, or elevated shell).
- `winget` available for package automation from `install/winget-packages.txt`.

Behavior:

- `install/bootstrap-windows.ps1` validates Windows runtime.
- Uses `install/winget-packages.txt` when `winget` is available.
- Validates winget package IDs and symlink capability before mutation.
- Backs up then links `~/.zshrc` and `~/.zprofile`.
- If `winget` is missing, package installation is skipped (non-destructive default).

## Linux (Secondary)

Linux is not a first-class bootstrap target in this repo today.

- `install/bootstrap.zsh` exits on non-Darwin systems.
- You can still reuse parts of `config/zsh/` manually.
- Package and desktop automation are not implemented for Linux here.

## Cross-Platform Caveats

- Several aliases are legacy Linux-centric (pacman/yay/system commands).
- Homebrew paths differ by architecture (`/opt/homebrew` vs `/usr/local`).
- GUI app casks in `brew/Brewfile` are macOS-specific.

## Future Expansion

If Linux bootstrap is added, keep it in a separate explicit entrypoint
(`install/bootstrap-linux.sh`) rather than weakening current macOS guarantees.

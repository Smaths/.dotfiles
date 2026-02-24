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

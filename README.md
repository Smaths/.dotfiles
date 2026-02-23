# Dotfiles

macOS-focused dotfiles for fast, repeatable machine setup.

## What This Repo Manages

- Homebrew packages and apps via `brew/Brewfile`
- Zsh config under `config/zsh`
- GitHub CLI config under `config/gh`
- Interactive macOS preference setup in `install/macos.zsh`

## Quick Start (Fresh or Existing Mac)

Clone into `$HOME`:

```zsh
cd ~
git clone <your-repo-url> .dotfiles
```

Run bootstrap:

```zsh
~/.dotfiles/install/bootstrap.zsh
```

Useful options:

```zsh
~/.dotfiles/install/bootstrap.zsh --dry-run
~/.dotfiles/install/bootstrap.zsh --skip-macos
```

## Bootstrap

`install/bootstrap.zsh` runs this process:

1. Install Homebrew if missing.
2. Resolve and print which Homebrew binary is used (supports `/opt/homebrew/bin/brew` and `/usr/local/bin/brew`).
3. Load Homebrew into the current shell (`brew shellenv`).
4. Install `git` via Homebrew when missing.
5. Install formulae and casks from `brew/Brewfile` using verbose output.
6. Create symlinks:
   - `~/.zshrc` -> `~/.dotfiles/config/zsh/.zshrc`
   - `~/.zprofile` -> `~/.dotfiles/config/zsh/.zprofile`
7. Back up existing `~/.zshrc` / `~/.zprofile` before relinking using:
   - `~/.zshrc.bak.<timestamp>`
   - `~/.zprofile.bak.<timestamp>`
8. Call `install/macos.zsh` for interactive macOS settings prompts.

Supported flags:

- `--dry-run`: print actions without making changes.
- `--skip-macos`: skip interactive macOS settings.
- `--skip-macros`: alias for `--skip-macos`.

## Interactive macOS Setup

`install/macos.zsh` prompts `Y/N` for each change, including:

- Disable natural scrolling
- Map Caps Lock to Control (session-level `hidutil`)
- Finder list view
- Finder full path in title
- Finder search current folder
- Dock auto-hide
- Dock minimize effect (`scale`)
- Restart Finder and Dock

Run it directly:

```zsh
~/.dotfiles/install/macos.zsh
```

## Zsh Layout

Main entry points:

- `config/zsh/.zshrc`
- `config/zsh/.zprofile`

Supporting files:

- `config/zsh/options.zsh`
- `config/zsh/path.zsh`
- `config/zsh/env.zsh`
- `config/zsh/completion.zsh`
- `config/zsh/plugins.zsh`
- `config/zsh/aliases.zsh`
- `config/zsh/functions/*.zsh`

### Startup Performance Decisions

This repo intentionally separates login-shell and interactive-shell concerns:

- `.zprofile` only loads `path.zsh` (minimal login setup).
- `.zshrc` loads `options.zsh`, `env.zsh`, completions, plugins, and aliases.

Why:

- Avoid duplicated startup work by preventing `env.zsh` from being sourced twice.
- Keep login startup minimal and predictable.

Node/NVM is configured for lazy loading:

- `nvm` is not fully initialized at shell startup.
- On first use of `nvm`, `node`, `npm`, `npx`, or `corepack`, `nvm.sh` is loaded with `--no-use`.

Why:

- Startup profile time showed `nvm_auto`/`nvm` as the dominant shell startup cost.
- Lazy loading keeps startup fast while preserving Node workflows.

If you need NVM loaded immediately in a shell session:

```zsh
nvm current
```

### Measured Improvement

From profiling before/after this change:

- Before lazy loading: `nvm_auto` / `nvm` dominated startup (about `~467ms`, ~99% of startup profile).
- After lazy loading with `--no-use`: `nvm_auto` is effectively negligible on startup (`~0.01ms` in profile output), and NVM work happens only when Node tooling is used.

Important: use a clean startup measurement to compare shell init performance:

```zsh
ZSH_PROFILE_STARTUP=1 zsh -i -c exit
```

If you profile after interactive usage in the same shell, zprof output will include completion/widget runtime (for example `zsh-autocomplete`), which can make totals look much higher than actual startup cost.

> [!NOTE] Machine-local overrides
> Want to override something without affecting the core settings. Use the `local.zsh` file. `local.zsh` is intentionally ignored by Git.
>
> ```zsh
> cp ~/.dotfiles/config/zsh/local.example.zsh ~/.dotfiles/config/zsh/local.zsh
> ```

## Re-running Safely

Running bootstrap again is expected and safe:

- `brew bundle` skips already installed items.
- Existing shell files are only replaced after backup.
- macOS settings only change when you answer `y`.

Optional pre-check before full run:

```zsh
brew bundle check --file ~/.dotfiles/brew/Brewfile
```

## Troubleshooting

- `brew: command not found`:
  - Run `eval "$(/opt/homebrew/bin/brew shellenv)"` in the current shell.
  - Bootstrap also resolves Homebrew directly from standard paths.

- Bootstrap appears stuck at "Installing from Brewfile":
  - This is usually a long download/cask install.
  - Re-run manually to inspect progress:
    ```zsh
    /opt/homebrew/bin/brew bundle install --verbose --file ~/.dotfiles/brew/Brewfile
    ```

- Cask conflict error (example: "existing App is different from the one being installed"):
  - Move or remove the existing app bundle from `/Applications`.
  - Re-run the cask install:
    ```zsh
    brew install --cask <app-name>
    ```

## Notes

- Built for macOS.
- Supports both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Homebrew paths.
- Some keyboard remaps may require logout/reboot to fully persist, depending on macOS behavior.

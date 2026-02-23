
# Dot Files

🛠️ WIP. My configuration for my standard development and media creation OSX machines.

## OSX Settings

- **Trackpad**
  - Revert "Natural Scrolling".
- **Keyboard**
  - Change **Caps-Lock** modifier to **CTRL**.
- **Finder** (in descending order of use frequency)
  - Default view to list.
  - Hide all tags.
  - Show full path.
  - Set sidebar order:
    1. User directory
    2. Downloads
    3. Applications
    4. Developer _(needs to be created/added)_
    5. Audio Production _(needs to be created/added)_
    6. Design _(needs to be created/added)_
    7. Movies
    8. Music
    9. Pictures
    10. Recents
    11. Airdrop
  - Set new search window to search this folder.
- **Dock**
  - Enable auto-hide.
  - Minimize using _Scale_ effect.
- **Web Browser**
  - Extensions: Ad-Block Plus, Dark-Reader
  - Set file download location to _Ask for each download_.

## Homebrew Packages & Installing Apps via Cask

Use Homebrew and the included lists in the `brew` directory to install packages for development and core applications.
Make sure to install [Homebrew](https://brew.sh) before proceeding.

## ZSH Configuration

The ZSH setup is managed in the `zsh` directory and includes:

- **Prompt Customization**: Uses `prompt_purification` for a clean, informative prompt.
- **Navigation Enhancements**: Directory stack, auto-cd, typo correction, and advanced globbing for efficient movement and path handling.
- **Completion System**: Loads completions from Homebrew and custom sources, with menu selection and improved matching.
- **History Management**: Shares history across sessions, removes duplicates, and records command timestamps.
- **Plugins**: Integrates `zsh-bd`, `zsh-autocomplete`, `fzf`, and OpenClaw completions for productivity.
- **Aliases**: Loads custom aliases from the `aliases` directory and provides GitHub Copilot shell helpers if `gh` and Copilot extension are installed.
- **Environment Setup**: Configures Node (NVM), PHP (Herd), and updates PATH for development tools.
- **Syntax Highlighting**: Enables syntax highlighting for better command visibility.

To use this configuration, source `.zshrc` and `.zprofile` from the `zsh` directory in your shell startup files.

### Core Brew Packages

- [fzf](https://github.com/junegunn/fzf): Fuzzy finder for terminal.
- gh: GitHub command line tool.
- node: Install node.
- nvm: Node version manager.
- [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete): Auto-complete commands for convenience.
- [zsh-completions](https://github.com/zsh-users/zsh-completions): Addtional completion defintions for Zsh.
- [zsh-syntax-highlights](https://github.com/zsh-users/zsh-syntax-highlighting): Color syntax highlighting.

## Installation

Clone into your `$HOME` directory. Install homebrew and associated packages.

### Install Homebrew Content

Locate files in `brew` folder. Open terminal and run the following command for each file in the `brew` folder.

Install Brews from File

```zsh
xargs brew install < brews_core.txt
```

Install Casks from File

```zsh
xargs brew install --cask < casks_core.txt
```

## References

This project is inspired by Matthieu Cneude's writing and dotfiles.

- [Configuring Zsh Without Dependencies](https://thevaluable.dev/zsh-install-configure-mouseless/)
- [Phantas0s dotfiles GitHub](https://github.com/Phantas0s/.dotfiles)

## Notes

> [!WARNING]
> All files are configured for ARM chips. Homebrew installation differs between x86 (Intel) and ARM (Apple Silicon), so the `.zshrc` and other files may need their locations corrected if installing these config files onto a different chipset than the one that was used to create these config files.

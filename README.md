
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
Use homebrew and included lists in `brew` directory to install packages for development and core applications using Homebrew. 

Make sure to install [Homebrew](https://brew.sh) before proceeding.

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
```
xargs brew install < brews_core.txt
```

Install Casks from File
```
xargs brew install --cask < casks_core.txt
```

## References

This project is inspired by Matthieu Cneude's writing and dotfiles.

- [Configuring Zsh Without Dependencies](https://thevaluable.dev/zsh-install-configure-mouseless/)
- [Phantas0s dotfiles GitHub](https://github.com/Phantas0s/.dotfiles)

## Notes
> [!WARNING]  
> All files are configured for ARM chips. Homebrew installation differs between x86 (Intel) and ARM (Apple Silicon), so the `.zshrc` and other files may need their locations corrected if installing these config files onto a different chipset than the one that was used to create these config files.  

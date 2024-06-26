
# Dot Files

## Description

🛠️ WIP. My configuration for my standard development and media creation osx machines.

## Getting Started

### Dependencies

- Homebrew
- zsh
- fzf
- git
- zsh-autocomplete
- zsh-completions
- zsh-syntax-highlightsas

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

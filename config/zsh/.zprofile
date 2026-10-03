# Login-shell environment loader.
# Initialize PATH once here; interactive child shells inherit it.
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Homebrew before path.zsh, deliberately. `brew shellenv` exports HOMEBREW_*,
# INFOPATH, and the completions fpath entry, and runs path_helper so man pages
# resolve. It also *prepends* its prefix to PATH -- running it afterwards would
# put brew's binaries ahead of the mise shims and shadow the per-project
# toolchain. First match wins, so Apple Silicon beats Intel.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

source "$DOTFILES_DIR/config/zsh/path.zsh"

# PATH management (macOS / Homebrew friendly).
# `-g` so the tied path/PATH pair stays global even if this file is ever sourced
# from inside a function.
typeset -gU path PATH

# mise-managed runtimes. Shims are the single activation mechanism: they work in
# login, non-interactive, and non-zsh contexts, and still resolve per-project
# versions from .nvmrc, .node-version, and packageManager. Do not also add
# `mise activate` -- running both mechanisms is unsupported.
MISE_SHIMS_DIR="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"

# Declare managed prefixes once in effective precedence order -- this list reads
# top-to-bottom as highest-to-lowest priority. Mise shims lead deliberately: they
# must beat the Homebrew copies of the same runtimes (node, python) so projects
# resolve their pinned versions. Do not reorder without that in mind. Only add
# paths that exist so fresh machines do not accumulate inert entries.
typeset -ga DOTFILES_PATH_PREFIXES
[[ -d "$MISE_SHIMS_DIR" ]] && DOTFILES_PATH_PREFIXES+=("$MISE_SHIMS_DIR")
[[ -d "$HOME/.unity/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/.unity/bin")
[[ -d /opt/homebrew/opt/mysql@8.4/bin ]] && DOTFILES_PATH_PREFIXES+=(/opt/homebrew/opt/mysql@8.4/bin)
[[ -d /usr/local/opt/mysql@8.4/bin ]] && DOTFILES_PATH_PREFIXES+=(/usr/local/opt/mysql@8.4/bin)
[[ -d "$HOME/Library/Application Support/Herd/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/Library/Application Support/Herd/bin")
[[ -d /opt/homebrew/bin ]] && DOTFILES_PATH_PREFIXES+=(/opt/homebrew/bin /opt/homebrew/sbin)
[[ -d /usr/local/bin ]] && DOTFILES_PATH_PREFIXES+=(/usr/local/bin /usr/local/sbin)
[[ -d "$HOME/.config/mcp/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/.config/mcp/bin")
[[ -d "$HOME/.opencode/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/.opencode/bin")
[[ -d "$HOME/.local/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/.local/bin")
[[ -d "$HOME/bin" ]] && DOTFILES_PATH_PREFIXES+=("$HOME/bin")

# Apple and Xcode Python remain available through their system paths. Do not
# expose version-specific `pip install --user` scripts as a global environment.
# This strips an entry no longer added here, so it only cleans a PATH inherited
# from the pre-mise setup -- it is a migration, safe to delete once every machine
# has logged in fresh. Must stay a basic glob: EXTENDED_GLOB is not set yet when
# .zprofile sources this file.
path=("${(@)path:#$HOME/Library/Python/*/bin}")
path=("${DOTFILES_PATH_PREFIXES[@]}" "${path[@]}")

unset DOTFILES_PATH_PREFIXES MISE_SHIMS_DIR

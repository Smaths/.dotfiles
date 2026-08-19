# Zsh plugin sources shared by the macOS bootstrap and its tests.
#
# These plugins are cloned instead of installed from a package manager so the
# load paths in config/zsh/plugins.zsh are identical on macOS and Linux, and so
# the plugin set is not tied to a Homebrew prefix.
#
# Required caller inputs (see install/lib/common.sh, which must be sourced first):
# - DRY_RUN, VERBOSE, and run_cmd
#
# Keep this file within the syntax supported by both Bash and Zsh.
# shellcheck shell=bash

# One "name|url" entry per line. A plain string keeps iteration identical in
# Bash and Zsh, which index arrays differently.
ZSH_PLUGIN_SPECS='fzf-tab|https://github.com/Aloxaf/fzf-tab.git
zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git
fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting.git'

# Resolved the same way config/zsh/env.zsh resolves it, so bootstrap and the
# shell always agree on one location.
zsh_plugin_root() {
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
}

zsh_plugin_count() {
  printf '%s\n' "$ZSH_PLUGIN_SPECS" | grep -c '|'
}

# Clone missing plugins into "$1"; refresh existing clones only when "$2" is 1.
# Reports results through ZSH_PLUGINS_CLONED, ZSH_PLUGINS_UPDATED,
# ZSH_PLUGINS_CURRENT, and ZSH_PLUGINS_UNMANAGED.
sync_zsh_plugins() {
  local root="${1:-}"
  local upgrade="${2:-0}"
  local name
  local url
  local dest

  if [[ -z "$root" ]]; then
    printf 'ERROR: sync_zsh_plugins requires a plugin root\n' >&2
    return 1
  fi

  ZSH_PLUGINS_CLONED=0
  ZSH_PLUGINS_UPDATED=0
  ZSH_PLUGINS_CURRENT=0
  ZSH_PLUGINS_UNMANAGED=0

  run_cmd mkdir -p "$root"

  while IFS='|' read -r name url; do
    [[ -n "$name" ]] || continue
    dest="$root/$name"

    if [[ ! -e "$dest" ]]; then
      run_cmd git clone --depth 1 "$url" "$dest" || return 1
      ZSH_PLUGINS_CLONED=$((ZSH_PLUGINS_CLONED + 1))
      continue
    fi

    # Never rewrite a directory this repo did not create. A hand-managed or
    # half-copied plugin is left exactly as found and reported instead.
    if [[ ! -d "$dest/.git" ]]; then
      printf '  plugin: skipped %s (exists but is not a git clone)\n' "$dest" >&2
      ZSH_PLUGINS_UNMANAGED=$((ZSH_PLUGINS_UNMANAGED + 1))
      continue
    fi

    if ((upgrade)); then
      # --ff-only so a locally modified clone fails loudly instead of merging.
      run_cmd git -C "$dest" pull --ff-only --quiet || return 1
      ZSH_PLUGINS_UPDATED=$((ZSH_PLUGINS_UPDATED + 1))
    else
      if ((VERBOSE)); then
        printf '  plugin: already present %s\n' "$dest"
      fi
      ZSH_PLUGINS_CURRENT=$((ZSH_PLUGINS_CURRENT + 1))
    fi
  done <<EOF
$ZSH_PLUGIN_SPECS
EOF
}

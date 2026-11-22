# Zsh plugin sources shared by the macOS and Debian bootstraps.
# Required caller inputs: DRY_RUN and run_cmd from common.sh.
# Keep this file compatible with both Bash and Zsh.
# shellcheck shell=bash

# One "name|url" entry per line. Follow each repo's default branch.
ZSH_PLUGIN_SPECS='fzf-tab|https://github.com/Aloxaf/fzf-tab.git
zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git
fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting.git'

zsh_plugin_root() {
  # Ignore relative XDG paths so startup never searches the working directory.
  if [[ "${XDG_DATA_HOME:-}" == /* ]]; then
    printf '%s\n' "$XDG_DATA_HOME/zsh/plugins"
  else
    printf '%s\n' "$HOME/.local/share/zsh/plugins"
  fi
}

zsh_plugin_count() {
  printf '%s\n' "$ZSH_PLUGIN_SPECS" | grep -c '|'
}

_zsh_plugin_verify_origin() {
  local actual
  actual="$(git -C "$1" remote get-url --all origin)" || return 1
  if [[ "$actual" != "$2" ]]; then
    printf 'ERROR: plugin %s has an unexpected origin (expected %s)\n' "$1" "$2" >&2
    return 1
  fi
}

# Stage a new clone so a failed fetch never leaves a loadable partial plugin.
_zsh_plugin_install() {
  local dest="$1" url="$2" staging
  if ((DRY_RUN)); then
    printf '[dry-run] install plugin %s from %s at upstream HEAD\n' "$dest" "$url"
    return 0
  fi
  staging="$(mktemp -d "${dest}.install.XXXXXX")" || return 1
  if git init --quiet "$staging" &&
    git -C "$staging" remote add origin "$url" &&
    _zsh_plugin_verify_origin "$staging" "$url" &&
    git -C "$staging" fetch --quiet --no-tags --depth 1 origin HEAD &&
    git -C "$staging" checkout --quiet --detach FETCH_HEAD &&
    mv "$staging" "$dest"; then
    return 0
  fi
  rm -rf -- "$staging"
  return 1
}

# Install missing plugins from upstream HEAD. Existing clones are verified
# locally and only advanced with opt-in, and then only by fast-forward.
sync_zsh_plugins() {
  local root="${1:-}" upgrade="${2:-0}"
  local name url extra dest head dirty shallow target
  local -a fetch_args

  if [[ -z "$root" ]]; then
    printf 'ERROR: sync_zsh_plugins requires a plugin root\n' >&2
    return 1
  fi

  ZSH_PLUGINS_CLONED=0
  ZSH_PLUGINS_UPDATED=0
  ZSH_PLUGINS_UNCHANGED=0
  ZSH_PLUGINS_UNMANAGED=0

  run_cmd mkdir -p "$root" || return 1

  while IFS='|' read -r name url extra; do
    [[ -n "$name" ]] || continue
    if [[ -z "$url" || -n "$extra" ]]; then
      printf 'ERROR: plugin %s requires a name and URL only\n' "$name" >&2
      return 1
    fi
    dest="$root/$name"

    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
      _zsh_plugin_install "$dest" "$url" || return 1
      ZSH_PLUGINS_CLONED=$((ZSH_PLUGINS_CLONED + 1))
      continue
    fi

    # Do not follow symlinks or rewrite hand-managed directories/worktrees.
    if [[ -L "$dest" || ! -d "$dest/.git" || -L "$dest/.git" ]]; then
      printf '  plugin: skipped %s (not a managed git clone)\n' "$dest" >&2
      ZSH_PLUGINS_UNMANAGED=$((ZSH_PLUGINS_UNMANAGED + 1))
      continue
    fi

    _zsh_plugin_verify_origin "$dest" "$url" || return 1
    # git status may refresh the index on disk even when the tree is clean.
    dirty="$(GIT_OPTIONAL_LOCKS=0 git -C "$dest" status --porcelain --untracked-files=all)" || return 1
    if [[ -n "$dirty" ]]; then
      printf 'ERROR: plugin %s has local changes; left untouched\n' "$dest" >&2
      return 1
    fi
    head="$(git -C "$dest" rev-parse --verify HEAD)" || return 1
    if ((! upgrade)); then
      ZSH_PLUGINS_UNCHANGED=$((ZSH_PLUGINS_UNCHANGED + 1))
      continue
    fi
    if ((DRY_RUN)); then
      printf '[dry-run] fetch upstream HEAD and fast-forward plugin %s if possible\n' "$dest"
      continue
    fi

    # Shallow clones, including older pinned installs, need ancestry first.
    shallow="$(git -C "$dest" rev-parse --is-shallow-repository)" || return 1
    fetch_args=(--quiet --no-tags)
    if [[ "$shallow" == true ]]; then
      fetch_args+=(--unshallow)
    fi
    git -C "$dest" fetch "${fetch_args[@]}" origin HEAD || return 1
    target="$(git -C "$dest" rev-parse --verify 'FETCH_HEAD^{commit}')" || return 1
    if [[ "$head" == "$target" ]]; then
      ZSH_PLUGINS_UNCHANGED=$((ZSH_PLUGINS_UNCHANGED + 1))
      continue
    fi
    if ! git -C "$dest" merge-base --is-ancestor "$head" "$target"; then
      printf 'ERROR: plugin %s cannot fast-forward to upstream HEAD; checkout left untouched\n' "$dest" >&2
      return 1
    fi
    # Advance without moving a local branch, resetting, or forcing checkout.
    git -C "$dest" checkout --quiet --detach "$target" || return 1
    ZSH_PLUGINS_UPDATED=$((ZSH_PLUGINS_UPDATED + 1))
  done <<EOF
$ZSH_PLUGIN_SPECS
EOF
}

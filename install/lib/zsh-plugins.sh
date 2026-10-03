# Zsh plugin sources shared by the macOS bootstrap and its tests.
# Required caller inputs: DRY_RUN, VERBOSE, and run_cmd from common.sh.
# Keep this file compatible with both Bash and Zsh.
# shellcheck shell=bash

# One "name|url|commit" entry per line. Pins preserve the installed baseline;
# provenance and the review/update procedure are in docs/OPERATIONS.md.
# Never replace these with branch names or tags.
ZSH_PLUGIN_SPECS='fzf-tab|https://github.com/Aloxaf/fzf-tab.git|24105b15714bfec37989ed5c5b6e60f572253019
zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting.git|3d574ccf48804b10dca52625df13da5edae7f553'

zsh_plugin_root() {
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
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

_zsh_plugin_verify_fetch() {
  local actual
  actual="$(git -C "$1" rev-parse --verify 'FETCH_HEAD^{commit}')" || return 1
  if [[ "$actual" != "$2" ]]; then
    printf 'ERROR: plugin %s fetched a commit other than %s\n' "$1" "$2" >&2
    return 1
  fi
}

# Stage a new clone so a failed fetch never leaves a loadable partial plugin.
_zsh_plugin_install() {
  local dest="$1" url="$2" commit="$3" staging
  if ((DRY_RUN)); then
    printf '[dry-run] install plugin %s from %s at %s (detached HEAD)\n' "$dest" "$url" "$commit"
    return 0
  fi
  staging="$(mktemp -d "${dest}.install.XXXXXX")" || return 1
  if git init --quiet "$staging" &&
    git -C "$staging" remote add origin "$url" &&
    _zsh_plugin_verify_origin "$staging" "$url" &&
    git -C "$staging" fetch --quiet --depth 1 origin "$commit" &&
    _zsh_plugin_verify_fetch "$staging" "$commit" &&
    git -C "$staging" checkout --quiet --detach "$commit" &&
    mv "$staging" "$dest"; then
    return 0
  fi
  rm -rf -- "$staging"
  return 1
}

# Install missing pins; advance existing clones only when "$2" is 1.
# No pull/default branch resolution. Dirty, wrong-origin, or divergent clones
# fail rather than being reset. Mismatched pins without opt-in are reported.
sync_zsh_plugins() {
  local root="${1:-}" upgrade="${2:-0}"
  local name url commit dest head dirty shallow

  if [[ -z "$root" ]]; then
    printf 'ERROR: sync_zsh_plugins requires a plugin root\n' >&2
    return 1
  fi

  ZSH_PLUGINS_CLONED=0
  ZSH_PLUGINS_UPDATED=0
  ZSH_PLUGINS_CURRENT=0
  ZSH_PLUGINS_UNMANAGED=0
  ZSH_PLUGINS_PENDING=0

  run_cmd mkdir -p "$root" || return 1

  while IFS='|' read -r name url commit; do
    [[ -n "$name" ]] || continue
    if [[ ${#commit} -ne 40 || "$commit" == *[!0-9a-f]* ]]; then
      printf 'ERROR: plugin %s requires a full lowercase commit SHA\n' "$name" >&2
      return 1
    fi
    dest="$root/$name"

    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
      _zsh_plugin_install "$dest" "$url" "$commit" || return 1
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
    dirty="$(git -C "$dest" status --porcelain --untracked-files=all)" || return 1
    if [[ -n "$dirty" ]]; then
      printf 'ERROR: plugin %s has local changes; left untouched\n' "$dest" >&2
      return 1
    fi
    head="$(git -C "$dest" rev-parse --verify HEAD)" || return 1
    if [[ "$head" == "$commit" ]]; then
      ZSH_PLUGINS_CURRENT=$((ZSH_PLUGINS_CURRENT + 1))
      continue
    fi
    if ((! upgrade)); then
      printf '  plugin: %s is at %s, pin is %s; use --upgrade-plugins\n' "$name" "$head" "$commit" >&2
      ZSH_PLUGINS_PENDING=$((ZSH_PLUGINS_PENDING + 1))
      continue
    fi

    # Existing shallow clones need ancestry to prove a fast-forward. Fetch only
    # the pinned target, not upstream HEAD, even when completing that history.
    shallow="$(git -C "$dest" rev-parse --is-shallow-repository)" || return 1
    if [[ "$shallow" == true ]]; then
      run_cmd git -C "$dest" fetch --quiet --unshallow origin "$commit" || return 1
    else
      run_cmd git -C "$dest" fetch --quiet origin "$commit" || return 1
    fi
    if ((! DRY_RUN)); then
      _zsh_plugin_verify_fetch "$dest" "$commit" || return 1
      if ! git -C "$dest" merge-base --is-ancestor "$head" "$commit"; then
        printf 'ERROR: plugin %s cannot fast-forward to pin %s; left untouched\n' "$dest" "$commit" >&2
        return 1
      fi
    fi
    # Ancestry gate above provides --ff-only semantics without moving a local
    # branch. Never force checkout, reset, merge, or discard local changes.
    run_cmd git -C "$dest" checkout --quiet --detach "$commit" || return 1
    ZSH_PLUGINS_UPDATED=$((ZSH_PLUGINS_UPDATED + 1))
  done <<EOF
$ZSH_PLUGIN_SPECS
EOF
}

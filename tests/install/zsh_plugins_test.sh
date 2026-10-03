#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/../.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-plugins-test.XXXXXX")"
trap 'rm -rf -- "$TEST_TMP_ROOT"' EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3 (expected $1, got $2)"
}

# Real Git repositories, no network or user Git configuration.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
DRY_RUN=0
VERBOSE=0
source "$REPO_DIR/install/lib/common.sh"
source "$REPO_DIR/install/lib/zsh-plugins.sh"
assert_eq 3 "$(zsh_plugin_count)" 'manifest should contain three plugins'
while IFS='|' read -r name url commit; do
  [[ "$url" == https://github.com/*.git ]] || fail 'manifest must use canonical HTTPS URLs'
  [[ ${#commit} -eq 40 && "$commit" != *[!0-9a-f]* ]] || fail 'manifest must pin full SHAs'
done <<EOF
$ZSH_PLUGIN_SPECS
EOF
assert_eq "$TEST_TMP_ROOT/xdg/zsh/plugins" \
  "$(XDG_DATA_HOME="$TEST_TMP_ROOT/xdg" zsh_plugin_root)" 'XDG plugin root'
assert_eq "$TEST_TMP_ROOT/home/.local/share/zsh/plugins" \
  "$(HOME="$TEST_TMP_ROOT/home" XDG_DATA_HOME='' zsh_plugin_root)" 'default plugin root'

UPSTREAM="$TEST_TMP_ROOT/upstream"
URL="file://$UPSTREAM"
git init --quiet "$UPSTREAM"
printf 'first\n' >"$UPSTREAM/plugin.zsh"
git -C "$UPSTREAM" add .
git -C "$UPSTREAM" commit --quiet -m first
FIRST="$(git -C "$UPSTREAM" rev-parse HEAD)"
printf 'second\n' >>"$UPSTREAM/plugin.zsh"
git -C "$UPSTREAM" commit --quiet -am second
SECOND="$(git -C "$UPSTREAM" rev-parse HEAD)"
printf 'unreviewed HEAD\n' >>"$UPSTREAM/plugin.zsh"
git -C "$UPSTREAM" commit --quiet -am third
THIRD="$(git -C "$UPSTREAM" rev-parse HEAD)"

ROOT="$TEST_TMP_ROOT/plugins"
DEST="$ROOT/example"
ZSH_PLUGIN_SPECS="example|$URL|$FIRST"
sync_zsh_plugins "$ROOT" 0
assert_eq 1 "$ZSH_PLUGINS_CLONED" 'first run installs pin'
assert_eq "$FIRST" "$(git -C "$DEST" rev-parse HEAD)" 'must not install floating HEAD'
if git -C "$DEST" symbolic-ref -q HEAD; then fail 'new clone must be detached'; fi
sync_zsh_plugins "$ROOT" 0
assert_eq 1 "$ZSH_PLUGINS_CURRENT" 'rerun verifies pin'
sync_zsh_plugins "$ROOT" 1
assert_eq 0 "$ZSH_PLUGINS_UPDATED" 'explicit update at pin is a no-op'

ZSH_PLUGIN_SPECS="example|$URL|$SECOND"
sync_zsh_plugins "$ROOT" 0
assert_eq 1 "$ZSH_PLUGINS_PENDING" 'new pin needs separate opt-in'
assert_eq "$FIRST" "$(git -C "$DEST" rev-parse HEAD)" 'default run preserves HEAD'
DRY_RUN=1 sync_zsh_plugins "$ROOT" 1 >/dev/null
DRY_RUN=0
assert_eq "$FIRST" "$(git -C "$DEST" rev-parse HEAD)" 'dry upgrade preserves HEAD'
if git -C "$DEST" cat-file -e "$SECOND" 2>/dev/null; then fail 'dry upgrade must not fetch'; fi
sync_zsh_plugins "$ROOT" 1
assert_eq 1 "$ZSH_PLUGINS_UPDATED" 'explicit update advances shallow clone'
assert_eq "$SECOND" "$(git -C "$DEST" rev-parse HEAD)" 'upgrade stops at pin, not HEAD'

# Refuse mismatched or multiple remote URLs even when already at the pin.
git -C "$DEST" remote set-url origin "$TEST_TMP_ROOT/wrong"
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'wrong origin must fail'; fi
git -C "$DEST" remote set-url origin "$URL"
git -C "$DEST" config --add remote.origin.url "$TEST_TMP_ROOT/extra"
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'multiple origins must fail'; fi
git -C "$DEST" config --unset-all remote.origin.url
git -C "$DEST" remote set-url origin "$URL"

# Refuse unstaged, staged, and untracked local changes without discarding them.
printf 'local\n' >>"$DEST/plugin.zsh"
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'dirty clone must fail'; fi
git -C "$DEST" add plugin.zsh
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'staged changes must fail'; fi
git -C "$DEST" commit --quiet -m local
LOCAL="$(git -C "$DEST" rev-parse HEAD)"
printf 'keep\n' >"$DEST/untracked"
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'untracked files must fail'; fi
rm "$DEST/untracked"
ZSH_PLUGIN_SPECS="example|$URL|$THIRD"
if sync_zsh_plugins "$ROOT" 1 2>/dev/null; then fail 'divergence must fail'; fi
assert_eq "$LOCAL" "$(git -C "$DEST" rev-parse HEAD)" 'divergence must preserve local commit'

# Non-shallow updates also stop at pins, and downgrades are refused.
ROOT2="$TEST_TMP_ROOT/full"
mkdir -p "$ROOT2"
git clone --quiet "$UPSTREAM" "$ROOT2/example"
git -C "$ROOT2/example" remote set-url origin "$URL"
git -C "$ROOT2/example" checkout --quiet --detach "$FIRST"
ZSH_PLUGIN_SPECS="example|$URL|$SECOND"
sync_zsh_plugins "$ROOT2" 1
assert_eq "$SECOND" "$(git -C "$ROOT2/example" rev-parse HEAD)" 'full clone fast-forward'
ZSH_PLUGIN_SPECS="example|$URL|$FIRST"
if sync_zsh_plugins "$ROOT2" 1 2>/dev/null; then fail 'downgrade must fail'; fi

UNMANAGED_ROOT="$TEST_TMP_ROOT/unmanaged"
mkdir -p "$UNMANAGED_ROOT/example"
printf 'hand-managed\n' >"$UNMANAGED_ROOT/example/marker"
sync_zsh_plugins "$UNMANAGED_ROOT" 1 2>/dev/null
assert_eq 1 "$ZSH_PLUGINS_UNMANAGED" 'non-clone must be reported'
[[ -f "$UNMANAGED_ROOT/example/marker" ]] || fail 'non-clone must be preserved'
mkdir -p "$TEST_TMP_ROOT/symlink"
ln -s "$DEST" "$TEST_TMP_ROOT/symlink/example"
sync_zsh_plugins "$TEST_TMP_ROOT/symlink" 1 2>/dev/null
assert_eq 1 "$ZSH_PLUGINS_UNMANAGED" 'symlink must not be followed'

DRY_RUN=1 sync_zsh_plugins "$TEST_TMP_ROOT/dry" 0 >/dev/null
DRY_RUN=0
[[ ! -e "$TEST_TMP_ROOT/dry" ]] || fail 'dry install must not create directories'
ZSH_PLUGIN_SPECS="example|$URL|main"
if sync_zsh_plugins "$TEST_TMP_ROOT/invalid" 0 2>/dev/null; then fail 'branch pin must fail'; fi
ZSH_PLUGIN_SPECS="example|$URL|0000000000000000000000000000000000000000"
if sync_zsh_plugins "$TEST_TMP_ROOT/failed" 0 2>/dev/null; then fail 'missing pin must fail'; fi
[[ ! -e "$TEST_TMP_ROOT/failed/example" ]] || fail 'failed install must not publish a clone'
assert_eq 0 "$(find "$TEST_TMP_ROOT/failed" -mindepth 1 | wc -l | tr -d '[:space:]')" 'failed staging is cleaned'

# Package upgrades must not be wired to plugin upgrades.
# shellcheck disable=SC2016
grep -Fq 'sync_zsh_plugins "$ZSH_PLUGIN_ROOT" "$UPGRADE_PLUGINS"' \
  "$REPO_DIR/install/platforms/macos/bootstrap.zsh" || fail 'plugin updates must have their own flag'
printf 'ok - Zsh plugin installer helper (%s)\n' "${ZSH_VERSION:-$BASH_VERSION}"

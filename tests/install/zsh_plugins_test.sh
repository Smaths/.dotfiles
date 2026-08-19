#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/../.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-plugins-test.XXXXXX")"

cleanup() {
  rm -rf -- "$TEST_TMP_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "$expected" != "$actual" ]]; then
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

FAKE_BIN="$TEST_TMP_ROOT/bin"
GIT_LOG="$TEST_TMP_ROOT/git.log"
mkdir -p "$FAKE_BIN"

# Stand-in for git: records every invocation and fakes a clone by creating the
# destination with a .git directory, so no network access is required.
cat >"$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$FAKE_GIT_LOG"

if [[ "${1:-}" == "clone" ]]; then
  dest="${!#}"
  mkdir -p "$dest/.git"
fi
exit 0
EOF
chmod +x "$FAKE_BIN/git"

PATH="$FAKE_BIN:$PATH"
export FAKE_GIT_LOG="$GIT_LOG"

DRY_RUN=0
VERBOSE=0
# shellcheck source=install/lib/common.sh
source "$REPO_DIR/install/lib/common.sh"
# shellcheck source=install/lib/zsh-plugins.sh
source "$REPO_DIR/install/lib/zsh-plugins.sh"

PLUGIN_COUNT="$(zsh_plugin_count)"
[[ "$PLUGIN_COUNT" -ge 1 ]] || fail 'plugin manifest is empty'

# The installer must resolve the same directory config/zsh/.zshrc does.
assert_eq "$TEST_TMP_ROOT/xdg/zsh/plugins" \
  "$(XDG_DATA_HOME="$TEST_TMP_ROOT/xdg" zsh_plugin_root)" \
  'zsh_plugin_root should follow XDG_DATA_HOME'
assert_eq "$TEST_TMP_ROOT/home/.local/share/zsh/plugins" \
  "$(HOME="$TEST_TMP_ROOT/home" XDG_DATA_HOME='' zsh_plugin_root)" \
  'zsh_plugin_root should fall back to ~/.local/share'

# First run clones every plugin.
ROOT="$TEST_TMP_ROOT/plugins"
: >"$GIT_LOG"
sync_zsh_plugins "$ROOT" 0
assert_eq "$PLUGIN_COUNT" "$ZSH_PLUGINS_CLONED" 'first run should clone every plugin'
assert_eq "0" "$ZSH_PLUGINS_CURRENT" 'first run should report nothing as already present'
assert_eq "$PLUGIN_COUNT" "$(grep -c '^clone --depth 1 ' "$GIT_LOG")" 'first run should shallow-clone each plugin'

# Rerunning converges without touching the clones.
: >"$GIT_LOG"
sync_zsh_plugins "$ROOT" 0
assert_eq "0" "$ZSH_PLUGINS_CLONED" 'rerun should not clone again'
assert_eq "$PLUGIN_COUNT" "$ZSH_PLUGINS_CURRENT" 'rerun should report existing clones'
assert_eq "0" "$(wc -l <"$GIT_LOG" | tr -d '[:space:]')" 'rerun should not run git at all'

# Upgrades are opt-in and fast-forward only.
: >"$GIT_LOG"
sync_zsh_plugins "$ROOT" 1
assert_eq "$PLUGIN_COUNT" "$ZSH_PLUGINS_UPDATED" 'upgrade run should update every clone'
assert_eq "$PLUGIN_COUNT" "$(grep -c 'pull --ff-only' "$GIT_LOG")" 'upgrade run should fast-forward each clone'

# A directory the repo did not clone is reported, never rewritten.
UNMANAGED_ROOT="$TEST_TMP_ROOT/unmanaged"
UNMANAGED_NAME="$(printf '%s\n' "$ZSH_PLUGIN_SPECS" | sed -n '1s/|.*//p')"
mkdir -p "$UNMANAGED_ROOT/$UNMANAGED_NAME"
printf 'hand-managed\n' >"$UNMANAGED_ROOT/$UNMANAGED_NAME/marker"
: >"$GIT_LOG"
sync_zsh_plugins "$UNMANAGED_ROOT" 1 2>/dev/null
assert_eq "1" "$ZSH_PLUGINS_UNMANAGED" 'a non-clone directory should be reported as unmanaged'
[[ -f "$UNMANAGED_ROOT/$UNMANAGED_NAME/marker" ]] || fail 'a non-clone directory must be left untouched'
[[ "$(grep -c "$UNMANAGED_NAME" "$GIT_LOG")" -eq 0 ]] || fail 'git must not run against an unmanaged directory'

# Dry runs describe the work without creating anything.
DRY_ROOT="$TEST_TMP_ROOT/dry"
: >"$GIT_LOG"
DRY_RUN=1 sync_zsh_plugins "$DRY_ROOT" 0 >/dev/null
DRY_RUN=0
[[ ! -d "$DRY_ROOT" ]] || fail 'dry run must not create the plugin root'
assert_eq "0" "$(wc -l <"$GIT_LOG" | tr -d '[:space:]')" 'dry run must not run git'

if [[ -n "${ZSH_VERSION:-}" ]]; then
  shell_name="zsh $ZSH_VERSION"
else
  shell_name="bash $BASH_VERSION"
fi
printf 'ok - Zsh plugin installer helper (%s)\n' "$shell_name"

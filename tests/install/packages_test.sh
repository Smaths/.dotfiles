#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/../.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-packages-test.XXXXXX")"
trap 'rm -rf -- "$TEST_TMP_ROOT"' EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3 (expected $1, got $2)"
}
resolve() {
  package_groups_resolve "$@" | paste -sd' ' -
}
expect_error() {
  local label="$1"
  shift
  if package_groups_resolve "$@" >/dev/null 2>"$TEST_TMP_ROOT/err"; then
    fail "$label should fail"
  fi
  [[ -s "$TEST_TMP_ROOT/err" ]] || fail "$label should explain the failure"
}

source "$REPO_DIR/install/lib/packages.sh"

# Resolver behavior against a fixture directory.
FIXTURE="$TEST_TMP_ROOT/packages"
mkdir -p "$FIXTURE"
for group in core dev ai extra; do
  : >"$FIXTURE/$group.Brewfile"
done
cat >"$FIXTURE/profiles" <<'PROFILES'
# comment: ignored
slim: core dev
full:  core dev   ai # trailing comment
broken: dev
PROFILES

assert_eq 'slim full broken' "$(package_profile_names "$FIXTURE/profiles" | paste -sd' ' -)" 'profile names'
assert_eq 'ai core dev extra' "$(package_group_names "$FIXTURE" .Brewfile | paste -sd' ' -)" 'group names'
assert_eq 'core dev' "$(resolve "$FIXTURE" .Brewfile slim '' '')" 'slim profile'
assert_eq 'core dev ai' "$(resolve "$FIXTURE" .Brewfile full '' '')" 'whitespace and comments are ignored'
assert_eq 'core dev ai extra' "$(resolve "$FIXTURE" .Brewfile slim 'ai, extra' '')" 'additions append in order'
assert_eq 'core dev' "$(resolve "$FIXTURE" .Brewfile slim 'dev' '')" 'additions do not duplicate'
assert_eq 'core ai' "$(resolve "$FIXTURE" .Brewfile full '' 'dev')" 'removals drop groups'
assert_eq 'core dev' "$(resolve "$FIXTURE" .Brewfile slim '' 'ai')" 'removing an unselected group is a no-op'
expect_error 'unknown profile' "$FIXTURE" .Brewfile missing '' ''
expect_error 'unknown added group' "$FIXTURE" .Brewfile slim nope ''
expect_error 'unknown removed group' "$FIXTURE" .Brewfile slim '' nope
expect_error 'invalid group name' "$FIXTURE" .Brewfile slim '../core' ''
expect_error 'removing core' "$FIXTURE" .Brewfile full '' core
expect_error 'adding and removing one group' "$FIXTURE" .Brewfile full ai ai
expect_error 'profile without core' "$FIXTURE" .Brewfile broken '' ''

# Invariants for the real macOS package groups.
PACKAGES_DIR="$REPO_DIR/install/platforms/macos/packages"
profiles="$(package_profile_names "$PACKAGES_DIR/profiles")"
assert_eq '' "$(printf '%s\n' "$profiles" | sort | uniq -d)" 'profile names must be unique'
printf '%s\n' "$profiles" | grep -Fxq slim || fail 'slim profile must exist'
printf '%s\n' "$profiles" | grep -Fxq full || fail 'full profile must exist'
while IFS= read -r profile; do
  groups="$(package_profile_groups "$PACKAGES_DIR/profiles" "$profile")"
  assert_eq core "$(printf '%s\n' "$groups" | head -n 1)" "profile $profile must list core first"
  package_groups_resolve "$PACKAGES_DIR" .Brewfile "$profile" '' '' >/dev/null ||
    fail "profile $profile must resolve"
done <<PROFILES
$profiles
PROFILES

# A package lives in exactly one group.
duplicates="$(cat "$PACKAGES_DIR"/*.Brewfile |
  sed -nE 's/^[[:space:]]*(brew|cask|tap|mas)[[:space:]]+("[^"]+").*/\1 \2/p' |
  sort | uniq -d)"
assert_eq '' "$duplicates" 'packages must not appear in more than one group'

# Bootstrap needs these tools from the required group.
for formula in mise git-delta zsh; do
  grep -Fxq "brew \"$formula\"" "$PACKAGES_DIR/core.Brewfile" ||
    fail "core group must install $formula"
done

printf 'ok - package group resolver (%s)\n' "${BASH_VERSION:+bash $BASH_VERSION}${ZSH_VERSION:+zsh $ZSH_VERSION}"

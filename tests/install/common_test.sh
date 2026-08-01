#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/../.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-common-test.XXXXXX")"

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

assert_contains() {
  local value="$1"
  local expected="$2"
  local message="$3"
  case "$value" in
    *"$expected"*) ;;
    *) fail "$message" ;;
  esac
}

new_case_dir() {
  mktemp -d "$TEST_TMP_ROOT/case.XXXXXX"
}

backup_count() {
  local link_path="$1"
  local link_dir
  local link_name
  link_dir="$(dirname -- "$link_path")"
  link_name="$(basename -- "$link_path")"
  find "$link_dir" -maxdepth 1 -name "${link_name}.bak.*" -print | wc -l | tr -d '[:space:]'
}

DRY_RUN=0
VERBOSE=0
# shellcheck source=install/lib/common.sh
source "$REPO_DIR/install/lib/common.sh"

test_missing_path() {
  local case_dir
  local target
  local link_path
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'target\n' >"$target"

  link_with_backup "$target" "$link_path"

  [[ -L "$link_path" ]] || fail 'missing destination was not linked'
  assert_eq "$target" "$(readlink "$link_path")" 'missing destination linked to the wrong target'
  assert_eq 0 "$(backup_count "$link_path")" 'missing destination created a backup'
}

test_regular_file() {
  local case_dir
  local target
  local link_path
  local backup_path
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'target\n' >"$target"
  printf 'original\n' >"$link_path"

  link_with_backup "$target" "$link_path"

  [[ -L "$link_path" ]] || fail 'regular file was not replaced with a symlink'
  assert_eq "$target" "$(readlink "$link_path")" 'regular file linked to the wrong target'
  assert_eq 1 "$(backup_count "$link_path")" 'regular file did not create exactly one backup'
  backup_path="$(find "$case_dir" -maxdepth 1 -name 'link.bak.*' -print)"
  assert_eq original "$(sed -n '1p' "$backup_path")" 'regular file backup did not preserve content'
}

test_correct_link() {
  local case_dir
  local target
  local link_path
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'target\n' >"$target"
  ln -s "$target" "$link_path"

  link_with_backup "$target" "$link_path"

  assert_eq "$target" "$(readlink "$link_path")" 'correct link changed target'
  assert_eq 0 "$(backup_count "$link_path")" 'correct link created a backup'
}

test_stale_link() {
  local case_dir
  local old_target
  local target
  local link_path
  local backup_path
  case_dir="$(new_case_dir)"
  old_target="$case_dir/old-target"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'old\n' >"$old_target"
  printf 'target\n' >"$target"
  ln -s "$old_target" "$link_path"

  link_with_backup "$target" "$link_path"

  assert_eq "$target" "$(readlink "$link_path")" 'stale link was not replaced'
  assert_eq 1 "$(backup_count "$link_path")" 'stale link did not create exactly one backup'
  backup_path="$(find "$case_dir" -maxdepth 1 -name 'link.bak.*' -print)"
  [[ -L "$backup_path" ]] || fail 'stale link backup is not a symlink'
  assert_eq "$old_target" "$(readlink "$backup_path")" 'stale link backup did not preserve its target'
}

test_backup_collision() (
  local case_dir
  local target
  local link_path
  local backup_base
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  backup_base="$link_path.bak.20260801123456"
  printf 'target\n' >"$target"
  printf 'original\n' >"$link_path"
  printf 'collision\n' >"$backup_base"
  date() {
    printf '20260801123456\n'
  }

  link_with_backup "$target" "$link_path"

  assert_eq collision "$(sed -n '1p' "$backup_base")" 'existing backup collision was overwritten'
  assert_eq original "$(sed -n '1p' "$backup_base.1")" 'collision suffix backup did not preserve content'
  assert_eq "$target" "$(readlink "$link_path")" 'collision case linked to the wrong target'
)

test_dry_run() {
  local case_dir
  local target
  local link_path
  local output
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'target\n' >"$target"
  printf 'original\n' >"$link_path"
  DRY_RUN=1

  output="$(link_with_backup "$target" "$link_path")"

  [[ ! -L "$link_path" ]] || fail 'dry-run replaced a regular file'
  assert_eq original "$(sed -n '1p' "$link_path")" 'dry-run changed regular file content'
  assert_eq 0 "$(backup_count "$link_path")" 'dry-run created a backup'
  assert_contains "$output" "link: would back up $link_path" 'dry-run did not report the planned backup'
  assert_contains "$output" '[dry-run] ln' 'dry-run did not report the planned symlink command'

  link_path="$case_dir/missing-link"
  output="$(link_with_backup "$target" "$link_path")"
  [[ ! -e "$link_path" && ! -L "$link_path" ]] || fail 'dry-run created a missing destination'
  assert_contains "$output" '[dry-run] ln' 'dry-run did not report a missing-destination link'
  DRY_RUN=0
}

test_repeated_runs() {
  local case_dir
  local target
  local link_path
  case_dir="$(new_case_dir)"
  target="$case_dir/target"
  link_path="$case_dir/link"
  printf 'target\n' >"$target"
  printf 'original\n' >"$link_path"

  link_with_backup "$target" "$link_path"
  link_with_backup "$target" "$link_path"
  link_with_backup "$target" "$link_path"

  assert_eq "$target" "$(readlink "$link_path")" 'repeated runs changed the link target'
  assert_eq 1 "$(backup_count "$link_path")" 'repeated runs created additional backups'
}

test_missing_path
test_regular_file
test_correct_link
test_stale_link
test_backup_collision
test_dry_run
test_repeated_runs

if [[ -n "${ZSH_VERSION:-}" ]]; then
  shell_name="zsh $ZSH_VERSION"
else
  shell_name="bash $BASH_VERSION"
fi
printf 'ok - shared bootstrap helpers (%s)\n' "$shell_name"

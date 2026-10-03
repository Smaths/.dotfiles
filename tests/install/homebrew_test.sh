#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/../.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-homebrew-test.XXXXXX")"

cleanup() {
  rm -rf -- "$TEST_TMP_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

FAKE_BIN="$TEST_TMP_ROOT/bin"
INSTALL_TMP="$TEST_TMP_ROOT/install-tmp"
RESULT_PATH="$TEST_TMP_ROOT/result"
mkdir -p "$FAKE_BIN" "$INSTALL_TMP"

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${FAKE_CURL_EXIT:-}" ]]; then
  exit "$FAKE_CURL_EXIT"
fi

output_path=""
while (($# > 0)); do
  case "$1" in
    --output)
      output_path="$2"
      shift 2
      ;;
    *) shift ;;
  esac
done

[[ -n "$output_path" ]]
cat >"$output_path" <<'INSTALLER'
#!/bin/bash
set -euo pipefail
IFS= read -r response
printf '%s\n' "$response" >"$HOMEBREW_TEST_RESULT"
exit "${FAKE_INSTALLER_EXIT:-0}"
INSTALLER
EOF
chmod +x "$FAKE_BIN/curl"

PATH="$FAKE_BIN:$PATH"
# shellcheck source=install/lib/homebrew.sh
source "$REPO_DIR/install/lib/homebrew.sh"

HOMEBREW_TEST_RESULT="$RESULT_PATH" TMPDIR="$INSTALL_TMP" install_homebrew <<'EOF'
prompt-response
EOF

[[ -f "$RESULT_PATH" ]] || fail 'installer did not run'
[[ "$(sed -n '1p' "$RESULT_PATH")" == "prompt-response" ]] || fail 'installer did not inherit stdin'
[[ -z "$(find "$INSTALL_TMP" -mindepth 1 -print -quit)" ]] || fail 'successful install left a temporary file'

if FAKE_CURL_EXIT=23 TMPDIR="$INSTALL_TMP" install_homebrew; then
  fail 'curl failure was not propagated'
else
  exit_code=$?
fi
[[ "$exit_code" -eq 23 ]] || fail 'curl failure returned the wrong exit code'
[[ -z "$(find "$INSTALL_TMP" -mindepth 1 -print -quit)" ]] || fail 'curl failure left a temporary file'

if FAKE_INSTALLER_EXIT=17 HOMEBREW_TEST_RESULT="$RESULT_PATH" TMPDIR="$INSTALL_TMP" install_homebrew <<'EOF'
prompt-response
EOF
then
  fail 'installer failure was not propagated'
else
  exit_code=$?
fi
[[ "$exit_code" -eq 17 ]] || fail 'installer failure returned the wrong exit code'
[[ -z "$(find "$INSTALL_TMP" -mindepth 1 -print -quit)" ]] || fail 'installer failure left a temporary file'

if [[ -n "${ZSH_VERSION:-}" ]]; then
  shell_name="zsh $ZSH_VERSION"
else
  shell_name="bash $BASH_VERSION"
fi
printf 'ok - Homebrew installer helper (%s)\n' "$shell_name"

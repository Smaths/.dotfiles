#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd)"

cd "$REPO_DIR"

prompt_path="config/zsh/prompts/purification/prompt_purification_setup"
expected_prompt_blob="3b912f41672482c9c7da94ba930331182da799e8"
[[ -f "$prompt_path" ]] || {
  printf 'missing vendored prompt: %s\n' "$prompt_path" >&2
  exit 1
}
[[ "$(git hash-object "$prompt_path")" == "$expected_prompt_blob" ]] || {
  printf 'vendored prompt does not match the recorded upstream blob: %s\n' "$prompt_path" >&2
  exit 1
}

git ls-files -z --cached --others --exclude-standard -- '*.sh' '*.bash' 'config/bash/.bashrc' | xargs -0 shellcheck
git ls-files -z --cached --others --exclude-standard -- '*.zsh' | xargs -0 zsh -n
zsh -n "$prompt_path"
git ls-files -z --cached --others --exclude-standard -- '*.sh' '*.zsh' '*.bash' 'config/bash/.bashrc' | xargs -0 shfmt -d -i 2 -ci
sh -n install/bootstrap.sh
ZSH_CONFIG_DIR="$REPO_DIR/config/zsh" zsh -fc 'source "$ZSH_CONFIG_DIR/options.zsh"; typeset -f prompt_purification_setup >/dev/null'
bash tests/install/common_test.sh
zsh tests/install/common_test.sh
bash tests/install/homebrew_test.sh
zsh tests/install/homebrew_test.sh
git diff --check

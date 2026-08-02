#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd)"

cd "$REPO_DIR"

uv_config_path="config/uv/uv.toml"
[[ -f "$uv_config_path" ]] || {
  printf 'missing uv config: %s\n' "$uv_config_path" >&2
  exit 1
}
grep -Fxq 'python-preference = "only-managed"' "$uv_config_path" || {
  printf 'uv must use only uv-managed Python interpreters\n' >&2
  exit 1
}
path_test_home="$(mktemp -d)"
trap 'rm -rf "$path_test_home"' EXIT
mkdir -p "$path_test_home/.local/share/mise/shims" "$path_test_home/.local/bin" "$path_test_home/Library/Python/3.9/bin"
HOME="$path_test_home" ZSH_PATH_FILE="$REPO_DIR/config/zsh/path.zsh" zsh -fc '
  path=("$HOME/Library/Python/3.9/bin" /usr/bin /bin)
  source "$ZSH_PATH_FILE"
  [[ "$path[1]" == "$HOME/.local/share/mise/shims" ]]
  (( ${path[(Ie)$HOME/.local/bin]} > 0 ))
  (( ${path[(Ie)$HOME/Library/Python/3.9/bin]} == 0 ))
  (( ${path[(Ie)/usr/bin]} > 0 ))
'

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

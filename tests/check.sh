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

brewfile_path="install/platforms/macos/Brewfile"
for retired in zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting; do
  if grep -Fq "brew \"$retired\"" "$brewfile_path"; then
    printf '%s is now a git clone in install/lib/zsh-plugins.sh; remove it from %s\n' \
      "$retired" "$brewfile_path" >&2
    exit 1
  fi
done
if grep -Eq '^[[:space:]]*brew "(go(@[^"]*)?|node(@[^"]*)?|pnpm)"' "$brewfile_path"; then
  printf 'Go, Node.js, and pnpm are mise-managed; remove duplicate runtimes from %s\n' \
    "$brewfile_path" >&2
  exit 1
fi

creative_brewfile_path="install/platforms/macos/Brewfile.creative"
[[ -f "$creative_brewfile_path" ]] || {
  printf 'missing optional creative manifest: %s\n' "$creative_brewfile_path" >&2
  exit 1
}
if grep -Eq '^[[:space:]]*cask "unity"' "$brewfile_path" "$creative_brewfile_path"; then
  printf 'manage exact Unity editors through Hub/Unity CLI, not the rolling unity cask\n' >&2
  exit 1
fi
if grep -Fq 'cask "unity-hub"' "$brewfile_path" ||
  ! grep -Fxq 'cask "unity-hub"' "$creative_brewfile_path"; then
  printf 'Unity Hub belongs only in %s\n' "$creative_brewfile_path" >&2
  exit 1
fi
if ! grep -Fq -- '--creative) INSTALL_CREATIVE=1' install/platforms/macos/bootstrap.zsh ||
  ! grep -Fq "CREATIVE_BREWFILE=\"\$SCRIPT_DIR/Brewfile.creative\"" install/platforms/macos/bootstrap.zsh; then
  printf 'macOS bootstrap must include the creative Brewfile only behind --creative\n' >&2
  exit 1
fi

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

shell_files=()
zsh_files=()
while IFS= read -r -d '' path; do
  [[ -f "$path" ]] || continue
  case "$path" in
    *.sh | *.bash | config/bash/.bashrc) shell_files+=("$path") ;;
  esac
  case "$path" in
    *.zsh) zsh_files+=("$path") ;;
  esac
done < <(git ls-files -z --cached --others --exclude-standard -- '*.sh' '*.zsh' '*.bash' 'config/bash/.bashrc')
shellcheck "${shell_files[@]}"
for path in "${zsh_files[@]}"; do zsh -n "$path"; done
zsh -n "$prompt_path"
shfmt -ln=bash -d -i 2 -ci "${shell_files[@]}"
shfmt -ln=zsh -d -i 2 -ci "${zsh_files[@]}"
sh -n install/bootstrap.sh
ZSH_CONFIG_DIR="$REPO_DIR/config/zsh" zsh -fc 'source "$ZSH_CONFIG_DIR/options.zsh"; typeset -f prompt_purification_setup >/dev/null'
bash tests/install/common_test.sh
zsh tests/install/common_test.sh
bash tests/install/homebrew_test.sh
zsh tests/install/homebrew_test.sh
bash tests/install/zsh_plugins_test.sh
zsh tests/install/zsh_plugins_test.sh
zsh -f tests/zsh_startup_test.zsh
git diff --check

#!/usr/bin/env bash
# Probe strings are evaluated in child shells.
# shellcheck disable=SC2016
set -euo pipefail

REPO_DIR="${1:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-shell-path.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT
test_home="$TEST_ROOT/home"
mkdir -p "$test_home/.local/bin" "$test_home/.local/share/mise/shims"
for tool in codex claude herdr; do
  printf '#!/bin/sh\nexit 0\n' >"$test_home/.local/bin/$tool"
  chmod +x "$test_home/.local/bin/$tool"
done
printf '#!/bin/sh\nexit 0\n' >"$test_home/.local/share/mise/shims/pi"
chmod +x "$test_home/.local/share/mise/shims/pi"
ln -s "$REPO_DIR/config/zsh/.zprofile" "$test_home/.zprofile"
ln -s "$REPO_DIR/config/zsh/.zshrc" "$test_home/.zshrc"

probe='unset HISTFILE; SAVEHIST=0
for tool in codex claude herdr pi; do
  command -v "$tool" >/dev/null || exit 1
done
case "$PATH" in "$HOME/.local/share/mise/shims:"*) ;; *) exit 1 ;; esac
case ":$PATH:" in *":$HOME/.local/bin:"*":$HOME/.local/bin:"*) exit 1 ;; esac
case ":$PATH:" in *":$HOME/.local/share/mise/shims:"*":$HOME/.local/share/mise/shims:"*) exit 1 ;; esac'

failed=0
for mode in -lc -ic -lic; do
  if env -i HOME="$test_home" ZDOTDIR="$test_home" DOTFILES_DIR="$REPO_DIR" \
    PATH=/usr/local/bin:/usr/bin:/bin TERM=dumb \
    zsh "$mode" "$probe"; then
    printf 'ok - clean zsh %s resolves agent commands\n' "$mode"
  else
    printf 'FAIL - clean zsh %s cannot resolve agent commands\n' "$mode" >&2
    failed=1
  fi
done
if env -i HOME="$test_home" DOTFILES_DIR="$REPO_DIR" \
  PATH=/usr/local/bin:/usr/bin:/bin TERM=dumb \
  bash --noprofile --rcfile "$REPO_DIR/config/bash/.bashrc" -ic "$probe"; then
  printf 'ok - clean interactive Bash resolves agent commands\n'
else
  printf 'FAIL - clean interactive Bash cannot resolve agent commands\n' >&2
  failed=1
fi
# Sourcing .bashrc in a noninteractive shell must retain its early return.
env -i HOME="$test_home" DOTFILES_DIR="$REPO_DIR" PATH=/usr/bin:/bin \
  bash --noprofile --norc -c '. "$DOTFILES_DIR/config/bash/.bashrc"; test "$PATH" = /usr/bin:/bin'
exit "$failed"

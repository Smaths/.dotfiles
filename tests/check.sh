#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd)"

cd "$REPO_DIR"

git ls-files -z --cached --others --exclude-standard -- '*.sh' '*.bash' 'config/bash/.bashrc' | xargs -0 shellcheck
git ls-files -z --cached --others --exclude-standard -- '*.zsh' | xargs -0 zsh -n
git ls-files -z --cached --others --exclude-standard -- '*.sh' '*.zsh' '*.bash' 'config/bash/.bashrc' | xargs -0 shfmt -d -i 2 -ci
sh -n install/bootstrap.sh
bash tests/install/common_test.sh
zsh tests/install/common_test.sh
git diff --check

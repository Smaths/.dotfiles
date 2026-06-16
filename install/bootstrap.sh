#!/usr/bin/env sh
set -eu

# Unified Unix bootstrap entrypoint.
# Dispatches to the platform-specific bootstrap while keeping each script simple.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case "$(uname -s)" in
  Darwin)
    exec zsh "$script_dir/platforms/macos/bootstrap.zsh" "$@"
    ;;
  Linux)
    if [ -r /etc/os-release ] && grep -Eqi '^(ID|ID_LIKE)=.*debian' /etc/os-release; then
      exec bash "$script_dir/platforms/debian/bootstrap.sh" "$@"
    fi

    if [ -r /etc/debian_version ]; then
      exec bash "$script_dir/platforms/debian/bootstrap.sh" "$@"
    fi

    echo "ERROR: Unsupported Linux distribution. Debian-like systems are supported." >&2
    exit 1
    ;;
  *)
    echo "ERROR: Unsupported OS. On Windows, run install/bootstrap.ps1 from PowerShell." >&2
    exit 1
    ;;
esac

# Homebrew bootstrap helper shared by the macOS entrypoint and its tests.
# shellcheck shell=bash

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

install_homebrew() {
  local installer_path
  local install_exit_code=0
  local cleanup_exit_code=0

  installer_path="$(mktemp "${TMPDIR:-/tmp}/snarfum-homebrew-install.XXXXXX")"

  # Download first so the installer inherits the caller's terminal on stdin.
  # Piping curl into Bash makes Homebrew incorrectly select non-interactive mode.
  curl -fsSL "$HOMEBREW_INSTALL_URL" --output "$installer_path" || install_exit_code=$?
  if ((install_exit_code == 0)); then
    /bin/bash "$installer_path" || install_exit_code=$?
  fi

  rm -f -- "$installer_path" || cleanup_exit_code=$?
  if ((install_exit_code != 0)); then
    return "$install_exit_code"
  fi
  return "$cleanup_exit_code"
}

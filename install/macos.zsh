#!/usr/bin/env zsh
set -euo pipefail

# Interactive macOS preferences setup.
# Intended to be called from install/bootstrap.zsh.

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "==> macOS setup skipped: not running on Darwin"
  exit 0
fi

ask_yes_no() {
  local prompt="$1"
  local answer
  while true; do
    read -r "?$prompt [y/N]: " answer
    case "${answer:l}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

apply_default() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  case "$type" in
    bool) defaults write "$domain" "$key" -bool "$value" ;;
    int) defaults write "$domain" "$key" -int "$value" ;;
    string) defaults write "$domain" "$key" -string "$value" ;;
    *) echo "Unsupported defaults type: $type" >&2; return 1 ;;
  esac
}

echo "==> macOS interactive setup"

if ask_yes_no "Disable Natural Scrolling (Trackpad)"; then
  apply_default NSGlobalDomain com.apple.swipescrolldirection bool false
  echo "Applied: Natural Scrolling disabled"
fi

if ask_yes_no "Set Caps Lock to Control (requires logout/login)"; then
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' >/dev/null
  echo "Applied: Caps Lock remapped to Control for current session"
  echo "Note: This remap may not persist across reboot/login on all macOS versions."
fi

if ask_yes_no "Finder: use list view by default"; then
  apply_default com.apple.finder FXPreferredViewStyle string Nlsv
  echo "Applied: Finder list view"
fi

if ask_yes_no "Finder: show full POSIX path in window title"; then
  apply_default com.apple.finder _FXShowPosixPathInTitle bool true
  echo "Applied: Finder full path in title"
fi

if ask_yes_no "Finder: search current folder by default"; then
  apply_default com.apple.finder FXDefaultSearchScope string SCcf
  echo "Applied: Finder search scope current folder"
fi

if ask_yes_no "Dock: enable auto-hide"; then
  apply_default com.apple.dock autohide bool true
  echo "Applied: Dock auto-hide"
fi

if ask_yes_no "Dock: set minimize effect to Scale"; then
  apply_default com.apple.dock mineffect string scale
  echo "Applied: Dock minimize effect scale"
fi

if ask_yes_no "Restart Finder now to apply Finder changes"; then
  killall Finder >/dev/null 2>&1 || true
  echo "Finder restarted"
fi

if ask_yes_no "Restart Dock now to apply Dock changes"; then
  killall Dock >/dev/null 2>&1 || true
  echo "Dock restarted"
fi

echo "==> macOS setup complete"

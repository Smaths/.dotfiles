#!/usr/bin/env zsh
set -euo pipefail

# Interactive macOS preferences setup.
# Intended to be called from install/bootstrap.zsh.

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "──▶ macOS setup skipped: not running on Darwin"
  exit 0
fi

ask_yes_no_default() {
  local prompt="$1"
  local default_answer="${2:-n}"
  local answer
  local default_hint="[y/N]"
  local normalized_default="n"

  case "${default_answer:l}" in
    y|yes|1|true)
      default_hint="[Y/n]"
      normalized_default="y"
      ;;
    n|no|0|false|"")
      default_hint="[y/N]"
      normalized_default="n"
      ;;
    *)
      echo "Invalid default answer for prompt '$prompt': $default_answer" >&2
      return 1
      ;;
  esac

  while true; do
    read -r "?$prompt $default_hint: " answer
    case "${answer:l}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      "")
        if [[ "$normalized_default" == "y" ]]; then
          return 0
        fi
        return 1
        ;;
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

print_applied() {
  local message="$1"
  SETTINGS_LINES+=("✓ $message")
}

print_note() {
  local message="$1"
  SETTINGS_LINES+=("ℹ $message")
}

print_settings_box() {
  if (( ${#SETTINGS_LINES[@]} == 0 )); then
    return 0
  fi

  local header="macOS Settings Applied"
  local max_width=${#header}
  local line
  for line in "${SETTINGS_LINES[@]}"; do
    if (( ${#line} > max_width )); then
      max_width=${#line}
    fi
  done

  local inner_width=$((max_width + 2))
  local border
  border="$(printf '%*s' "$inner_width" '' | tr ' ' '─')"

  printf '┌%s┐\n' "$border"
  printf '│ %-*s │\n' "$max_width" "$header"
  printf '├%s┤\n' "$border"
  for line in "${SETTINGS_LINES[@]}"; do
    printf '│ %-*s │\n' "$max_width" "$line"
  done
  printf '└%s┘\n' "$border"
}

echo "──▶ macOS interactive setup"

typeset -A DEFAULTS_PRESET=(
  [natural_scrolling]="y"
  [caps_to_control]="y"
  [finder_list_view]="y"
  [finder_show_full_path]="y"
  [finder_search_current_folder]="y"
  [dock_autohide]="y"
  [dock_scale_effect]="y"
  [restart_finder_now]="y"
  [restart_dock_now]="y"
)
PROMPT_PER_SETTING=1
typeset -a SETTINGS_LINES=()

print_defaults_summary() {
  local label_width=44
  local settings_header="macOS Settings"
  local yes_icon="✓"
  local no_icon="✗"
  local natural_scrolling_icon="$no_icon"
  local caps_to_control_icon="$no_icon"
  local finder_list_view_icon="$no_icon"
  local finder_show_full_path_icon="$no_icon"
  local finder_search_current_folder_icon="$no_icon"
  local dock_autohide_icon="$no_icon"
  local dock_scale_effect_icon="$no_icon"
  local restart_finder_now_icon="$no_icon"
  local restart_dock_now_icon="$no_icon"

  [[ "${DEFAULTS_PRESET[natural_scrolling]}" == "y" ]] && natural_scrolling_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[caps_to_control]}" == "y" ]] && caps_to_control_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[finder_list_view]}" == "y" ]] && finder_list_view_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[finder_show_full_path]}" == "y" ]] && finder_show_full_path_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[finder_search_current_folder]}" == "y" ]] && finder_search_current_folder_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[dock_autohide]}" == "y" ]] && dock_autohide_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[dock_scale_effect]}" == "y" ]] && dock_scale_effect_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[restart_finder_now]}" == "y" ]] && restart_finder_now_icon="$yes_icon"
  [[ "${DEFAULTS_PRESET[restart_dock_now]}" == "y" ]] && restart_dock_now_icon="$yes_icon"

  format_defaults_label() {
    local label="$1"
    local dot_count=$((label_width - ${#label}))
    if (( dot_count < 3 )); then
      dot_count=3
    fi
    printf '%s %s' "$label" "$(printf '%*s' "$dot_count" '' | tr ' ' '.')"
  }

  local -a preset_lines=(
    "$(format_defaults_label "Disable Natural Scrolling (Trackpad)") $natural_scrolling_icon"
    "$(format_defaults_label "Set Caps Lock to Control") $caps_to_control_icon"
    "$(format_defaults_label "Finder list view") $finder_list_view_icon"
    "$(format_defaults_label "Finder full POSIX path in title") $finder_show_full_path_icon"
    "$(format_defaults_label "Finder search current folder") $finder_search_current_folder_icon"
    "$(format_defaults_label "Dock auto-hide") $dock_autohide_icon"
    "$(format_defaults_label "Dock minimize effect Scale") $dock_scale_effect_icon"
    "$(format_defaults_label "Restart Finder now") $restart_finder_now_icon"
    "$(format_defaults_label "Restart Dock now") $restart_dock_now_icon"
  )
  local max_width=${#settings_header}
  local line
  for line in "${preset_lines[@]}"; do
    if (( ${#line} > max_width )); then
      max_width=${#line}
    fi
  done
  local inner_width=$((max_width + 2))
  local border
  border="$(printf '%*s' "$inner_width" '' | tr ' ' '─')"

  printf '┌%s┐\n' "$border"
  printf '│ %-*s │\n' "$max_width" "$settings_header"
  printf '├%s┤\n' "$border"
  for line in "${preset_lines[@]}"; do
    printf '│ %-*s │\n' "$max_width" "$line"
  done
  printf '└%s┘\n' "$border"
}

select_prompt_mode() {
  local mode
  while true; do

cat <<'EOF'
Prompt mode:
  [1] Use defaults (no per-setting prompts)
  [2] Choose settings (prompt per setting)
  [3] Skip
EOF
    read -r "?Selection [1/2/3]: " mode
    case "$mode" in
      1)
        print_defaults_summary
        if ask_yes_no_default "Proceed (this will restart Finder and Dock if those options are enabled)?" "y"; then
          PROMPT_PER_SETTING=0
          return 0
        fi
        echo "Defaults not confirmed. Choose a mode again."
        ;;
      2)
        echo "Set the default answer for each setting (y/n). Press Enter to keep current."
        if ask_yes_no_default "──▶ Disable Natural Scrolling (Trackpad)" "${DEFAULTS_PRESET[natural_scrolling]}"; then DEFAULTS_PRESET[natural_scrolling]="y"; else DEFAULTS_PRESET[natural_scrolling]="n"; fi
        if ask_yes_no_default "──▶ Set Caps Lock to Control" "${DEFAULTS_PRESET[caps_to_control]}"; then DEFAULTS_PRESET[caps_to_control]="y"; else DEFAULTS_PRESET[caps_to_control]="n"; fi
        if ask_yes_no_default "──▶ Finder list view" "${DEFAULTS_PRESET[finder_list_view]}"; then DEFAULTS_PRESET[finder_list_view]="y"; else DEFAULTS_PRESET[finder_list_view]="n"; fi
        if ask_yes_no_default "──▶ Finder full POSIX path in title" "${DEFAULTS_PRESET[finder_show_full_path]}"; then DEFAULTS_PRESET[finder_show_full_path]="y"; else DEFAULTS_PRESET[finder_show_full_path]="n"; fi
        if ask_yes_no_default "──▶ Finder search current folder" "${DEFAULTS_PRESET[finder_search_current_folder]}"; then DEFAULTS_PRESET[finder_search_current_folder]="y"; else DEFAULTS_PRESET[finder_search_current_folder]="n"; fi
        if ask_yes_no_default "──▶ Dock auto-hide" "${DEFAULTS_PRESET[dock_autohide]}"; then DEFAULTS_PRESET[dock_autohide]="y"; else DEFAULTS_PRESET[dock_autohide]="n"; fi
        if ask_yes_no_default "──▶ Dock minimize effect Scale" "${DEFAULTS_PRESET[dock_scale_effect]}"; then DEFAULTS_PRESET[dock_scale_effect]="y"; else DEFAULTS_PRESET[dock_scale_effect]="n"; fi
        if ask_yes_no_default "──▶ Restart Finder now" "${DEFAULTS_PRESET[restart_finder_now]}"; then DEFAULTS_PRESET[restart_finder_now]="y"; else DEFAULTS_PRESET[restart_finder_now]="n"; fi
        if ask_yes_no_default "──▶ Restart Dock now" "${DEFAULTS_PRESET[restart_dock_now]}"; then DEFAULTS_PRESET[restart_dock_now]="y"; else DEFAULTS_PRESET[restart_dock_now]="n"; fi
        if ask_yes_no_default "Proceed (this may restart Finder/Dock depending on your choices)?" "y"; then
          PROMPT_PER_SETTING=0
          return 0
        fi
        echo "Cancelled. Returning to prompt mode selection."
        continue
        ;;
      3)
        echo "──▶ macOS setup skipped by user"
        echo ""
        return 2
        ;;
      *)
        echo "Please choose 1, 2, or 3 (empty input is ignored)."
        ;;
    esac
  done
}

set +e
select_prompt_mode
select_mode_exit=$?
set -e
if (( select_mode_exit == 2 )); then
  exit 20
elif (( select_mode_exit != 0 )); then
  exit "$select_mode_exit"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Disable Natural Scrolling (Trackpad)" "${DEFAULTS_PRESET[natural_scrolling]}" && DEFAULTS_PRESET[natural_scrolling]="y" || DEFAULTS_PRESET[natural_scrolling]="n"
fi
if [[ "${DEFAULTS_PRESET[natural_scrolling]}" == "y" ]]; then
  apply_default NSGlobalDomain com.apple.swipescrolldirection bool false
  print_applied "Natural Scrolling disabled"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Set Caps Lock to Control (requires logout/login)" "${DEFAULTS_PRESET[caps_to_control]}" && DEFAULTS_PRESET[caps_to_control]="y" || DEFAULTS_PRESET[caps_to_control]="n"
fi
if [[ "${DEFAULTS_PRESET[caps_to_control]}" == "y" ]]; then
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' >/dev/null
  print_applied "Caps Lock remapped to Control for current session"
  print_note "Caps Lock remap may not persist across reboot/login on all macOS versions."
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Finder: use list view by default" "${DEFAULTS_PRESET[finder_list_view]}" && DEFAULTS_PRESET[finder_list_view]="y" || DEFAULTS_PRESET[finder_list_view]="n"
fi
if [[ "${DEFAULTS_PRESET[finder_list_view]}" == "y" ]]; then
  apply_default com.apple.finder FXPreferredViewStyle string Nlsv
  print_applied "Finder list view"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Finder: show full POSIX path in window title" "${DEFAULTS_PRESET[finder_show_full_path]}" && DEFAULTS_PRESET[finder_show_full_path]="y" || DEFAULTS_PRESET[finder_show_full_path]="n"
fi
if [[ "${DEFAULTS_PRESET[finder_show_full_path]}" == "y" ]]; then
  apply_default com.apple.finder _FXShowPosixPathInTitle bool true
  print_applied "Finder full path in title"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Finder: search current folder by default" "${DEFAULTS_PRESET[finder_search_current_folder]}" && DEFAULTS_PRESET[finder_search_current_folder]="y" || DEFAULTS_PRESET[finder_search_current_folder]="n"
fi
if [[ "${DEFAULTS_PRESET[finder_search_current_folder]}" == "y" ]]; then
  apply_default com.apple.finder FXDefaultSearchScope string SCcf
  print_applied "Finder search scope current folder"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Dock: enable auto-hide" "${DEFAULTS_PRESET[dock_autohide]}" && DEFAULTS_PRESET[dock_autohide]="y" || DEFAULTS_PRESET[dock_autohide]="n"
fi
if [[ "${DEFAULTS_PRESET[dock_autohide]}" == "y" ]]; then
  apply_default com.apple.dock autohide bool true
  print_applied "Dock auto-hide"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Dock: set minimize effect to Scale" "${DEFAULTS_PRESET[dock_scale_effect]}" && DEFAULTS_PRESET[dock_scale_effect]="y" || DEFAULTS_PRESET[dock_scale_effect]="n"
fi
if [[ "${DEFAULTS_PRESET[dock_scale_effect]}" == "y" ]]; then
  apply_default com.apple.dock mineffect string scale
  print_applied "Dock minimize effect scale"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Restart Finder now to apply Finder changes" "${DEFAULTS_PRESET[restart_finder_now]}" && DEFAULTS_PRESET[restart_finder_now]="y" || DEFAULTS_PRESET[restart_finder_now]="n"
fi
if [[ "${DEFAULTS_PRESET[restart_finder_now]}" == "y" ]]; then
  killall Finder >/dev/null 2>&1 || true
  print_applied "Finder restarted"
fi

if (( PROMPT_PER_SETTING )); then
  ask_yes_no_default "Restart Dock now to apply Dock changes" "${DEFAULTS_PRESET[restart_dock_now]}" && DEFAULTS_PRESET[restart_dock_now]="y" || DEFAULTS_PRESET[restart_dock_now]="n"
fi
if [[ "${DEFAULTS_PRESET[restart_dock_now]}" == "y" ]]; then
  killall Dock >/dev/null 2>&1 || true
  print_applied "Dock restarted"
fi

print_settings_box

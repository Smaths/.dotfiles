# Shared bootstrap progress UI for POSIX-compatible shells.
# Keep this file presentation-only; platform bootstrap logic stays in platforms/.
# shellcheck shell=bash

ui_init() {
  UI_TITLE="${1:?ui_init requires a title}"
  UI_TOTAL_STEPS="${2:?ui_init requires a step count}"
  UI_CURRENT_STEP=0
  UI_CURRENT_STEP_LABEL=""
  UI_OK_COUNT=0
  UI_SKIP_COUNT=0
  UI_START_TS="$(date +%s)"
  UI_STEP_LABEL_WIDTH="${UI_STEP_LABEL_WIDTH:-34}"
  UI_COLOR_OK=""
  UI_COLOR_SKIP=""
  UI_COLOR_RESET=""
  ui_init_symbols
  ui_init_colors
}

ui_init_colors() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    UI_COLOR_OK="$(printf '\033[32m')"
    UI_COLOR_SKIP="$(printf '\033[33m')"
    UI_COLOR_RESET="$(printf '\033[0m')"
  fi
}

ui_init_symbols() {
  case "${DOTFILES_UI_STYLE:-auto}" in
    unicode)
      UI_UNICODE=1
      ;;
    ascii)
      UI_UNICODE=0
      ;;
    *)
      case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
        *UTF-8*|*utf-8*|*UTF8*|*utf8*) UI_UNICODE=1 ;;
        *) UI_UNICODE=0 ;;
      esac
      ;;
  esac

  if [ "$UI_UNICODE" -eq 1 ]; then
    UI_HEADER_LINE="──────────────────────────────────"
    UI_STEP_OK_SEP="┤"
    UI_STEP_SKIP_SEP="│"
    UI_OK_MARK="✓"
    UI_SKIP_MARK="↷"
    UI_USER_SKIP_MARK="⏭"
    UI_BOX_TL="┌"
    UI_BOX_TR="┐"
    UI_BOX_BL="└"
    UI_BOX_BR="┘"
    UI_BOX_H="─"
    UI_BOX_V="│"
    UI_SUMMARY_JOIN="•"
  else
    UI_HEADER_LINE="----------------------------------"
    UI_STEP_OK_SEP="|"
    UI_STEP_SKIP_SEP="|"
    UI_OK_MARK="OK"
    UI_SKIP_MARK="SKIP"
    UI_USER_SKIP_MARK="SKIP"
    UI_BOX_TL="+"
    UI_BOX_TR="+"
    UI_BOX_BL="+"
    UI_BOX_BR="+"
    UI_BOX_H="-"
    UI_BOX_V="|"
    UI_SUMMARY_JOIN="-"
  fi
}

ui_repeat() {
  local count="$1"
  local char="$2"
  if [ "$count" -le 0 ]; then
    return 0
  fi
  printf '%*s' "$count" '' | tr ' ' "$char"
}

ui_print_header() {
  printf '\n\n%s\n%s\n\n' "$UI_TITLE" "$UI_HEADER_LINE"
}

ui_start() {
  printf 'Starting bootstrap: %s steps\n\n' "$UI_TOTAL_STEPS"
}

ui_format_step_label() {
  local label="$1"
  local dot_count=$((UI_STEP_LABEL_WIDTH - ${#label}))
  if [ "$dot_count" -lt 3 ]; then
    dot_count=3
  fi
  printf '%s %s' "$label" "$(ui_repeat "$dot_count" '.')"
}

ui_step_start() {
  UI_CURRENT_STEP=$((UI_CURRENT_STEP + 1))
  UI_CURRENT_STEP_LABEL="$1"
}

ui_step_ok() {
  local detail="$1"
  UI_OK_COUNT=$((UI_OK_COUNT + 1))
  printf '%d/%d %s %s %s%s%s %s\n' \
    "$UI_CURRENT_STEP" \
    "$UI_TOTAL_STEPS" \
    "$UI_STEP_OK_SEP" \
    "$(ui_format_step_label "$UI_CURRENT_STEP_LABEL")" \
    "$UI_COLOR_OK" \
    "$UI_OK_MARK" \
    "$UI_COLOR_RESET" \
    "$detail"
}

ui_step_skip() {
  local detail="$1"
  UI_SKIP_COUNT=$((UI_SKIP_COUNT + 1))
  printf '%d/%d %s %s %s%s%s %s\n' \
    "$UI_CURRENT_STEP" \
    "$UI_TOTAL_STEPS" \
    "$UI_STEP_SKIP_SEP" \
    "$(ui_format_step_label "$UI_CURRENT_STEP_LABEL")" \
    "$UI_COLOR_SKIP" \
    "$UI_SKIP_MARK" \
    "$UI_COLOR_RESET" \
    "$detail"
}

ui_step_skip_user() {
  local detail="$1"
  UI_SKIP_COUNT=$((UI_SKIP_COUNT + 1))
  printf '%d/%d %s %s %s%s%s %s\n' \
    "$UI_CURRENT_STEP" \
    "$UI_TOTAL_STEPS" \
    "$UI_STEP_SKIP_SEP" \
    "$(ui_format_step_label "$UI_CURRENT_STEP_LABEL")" \
    "$UI_COLOR_SKIP" \
    "$UI_USER_SKIP_MARK" \
    "$UI_COLOR_RESET" \
    "$detail"
}

ui_summary() {
  local elapsed
  local summary_line
  local summary_width
  local summary_border
  elapsed="$(($(date +%s) - UI_START_TS))"
  summary_line="Done in ${elapsed}s ${UI_SUMMARY_JOIN} ${UI_OK_COUNT}/${UI_TOTAL_STEPS} completed ${UI_SUMMARY_JOIN} ${UI_SKIP_COUNT} skipped"
  summary_width=$((${#summary_line} + 2))
  summary_border="$(ui_repeat "$summary_width" "$UI_BOX_H")"
  printf '\n%s%s%s\n' "$UI_BOX_TL" "$summary_border" "$UI_BOX_TR"
  printf '%s %s %s\n' "$UI_BOX_V" "$summary_line" "$UI_BOX_V"
  printf '%s%s%s\n' "$UI_BOX_BL" "$summary_border" "$UI_BOX_BR"
}

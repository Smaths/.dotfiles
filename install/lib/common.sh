# Shared bootstrap helpers for Bash and Zsh.
#
# Required caller inputs:
# - DRY_RUN: 1 prints mutating commands without executing them; 0 executes them.
# - VERBOSE: 1 prints additional link details; 0 keeps output concise.
#
# Keep this file within the syntax supported by both Bash and Zsh.
# shellcheck shell=bash

run_cmd() {
  if ((DRY_RUN)); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

require_cmd() {
  local cmd="$1"
  local message="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf "ERROR: Missing required command '%s'. %s\n" "$cmd" "$message" >&2
    exit 1
  fi
}

next_backup_path() {
  local source_path="${1:?next_backup_path requires a source path}"
  local backup_base
  local backup_path
  local suffix=0

  backup_base="${source_path}.bak.$(date +%Y%m%d%H%M%S)"
  backup_path="$backup_base"

  while [[ -e "$backup_path" || -L "$backup_path" ]]; do
    suffix=$((suffix + 1))
    backup_path="${backup_base}.${suffix}"
  done

  printf '%s\n' "$backup_path"
}

link_with_backup() {
  local link_target="${1:-}"
  local link_path="${2:-}"
  local backup_path=""
  local current_target

  if [[ -z "$link_target" || -z "$link_path" ]]; then
    printf 'ERROR: link_with_backup requires target and link path\n' >&2
    return 1
  fi

  if [[ -L "$link_path" ]]; then
    current_target="$(readlink "$link_path")"
    if [[ "$current_target" == "$link_target" ]]; then
      if ((VERBOSE)); then
        printf '  link: already correct (%s -> %s)\n' "$link_path" "$link_target"
      fi
      return 0
    fi
    backup_path="$(next_backup_path "$link_path")"
  elif [[ -e "$link_path" ]]; then
    backup_path="$(next_backup_path "$link_path")"
  fi

  if [[ -n "$backup_path" ]]; then
    if ((DRY_RUN)); then
      printf '  link: would back up %s -> %s\n' "$link_path" "$backup_path"
    else
      run_cmd mv "$link_path" "$backup_path"
      if ((VERBOSE)); then
        printf '  link: backed up %s -> %s\n' "$link_path" "$backup_path"
      fi
    fi
  fi

  run_cmd ln -s "$link_target" "$link_path"
  if ((VERBOSE && ! DRY_RUN)); then
    printf '  link: created %s -> %s\n' "$link_path" "$link_target"
  fi
}

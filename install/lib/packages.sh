# Package groups and profiles shared by the platform bootstraps.
#
# A platform keeps one manifest per group in a packages directory
# (<dir>/<group><ext>, for example core.Brewfile) and a <dir>/profiles file
# that maps each profile name to an ordered list of groups:
#
#   slim: core dev utilities
#
# Each package lives in exactly one group, and profiles name only groups. The
# core group is required: every profile lists it and it cannot be removed.
#
# Keep this file within the syntax supported by Bash 3.2 and Zsh.
# shellcheck shell=bash

PACKAGE_REQUIRED_GROUP="core"

_package_error() {
  printf 'ERROR: %s\n' "$1" >&2
}

_package_valid_name() {
  case "$1" in
    "" | -* | *[!a-z0-9-]*) return 1 ;;
  esac
  return 0
}

# Print each comma- or whitespace-separated item of $1 on its own line.
_package_split() {
  printf '%s\n' "$1" | tr -s ', \t' '\n' | sed '/^$/d'
}

_package_join() {
  paste -sd, - | sed 's/,/, /g'
}

# Print the profile names defined in <profiles-file>, one per line.
package_profile_names() {
  sed -e 's/#.*//' "$1" | awk -F: 'NF > 1 { gsub(/[[:space:]]/, "", $1); if ($1 != "") print $1 }'
}

# Print the groups that profile <name> lists in <profiles-file>, one per line.
package_profile_groups() {
  local profiles_file="$1" profile="$2" groups
  if [[ ! -f "$profiles_file" ]]; then
    _package_error "missing package profiles file: $profiles_file"
    return 1
  fi
  if ! groups="$(sed -e 's/#.*//' "$profiles_file" | awk -F: -v want="$profile" '
    { name = $1; gsub(/[[:space:]]/, "", name) }
    NF > 1 && name == want { sub(/^[^:]*:/, ""); print; found = 1 }
    END { exit found ? 0 : 1 }')"; then
    _package_error "unknown profile '$profile' (available: $(package_profile_names "$profiles_file" | _package_join))"
    return 1
  fi
  _package_split "$groups"
}

# Print the group names that have a manifest in <dir> with extension <ext>.
package_group_names() {
  find "$1" -maxdepth 1 -type f -name "*$2" -print |
    awk -v ext="$2" '{ sub(/.*\//, ""); print substr($0, 1, length($0) - length(ext)) }' |
    sort
}

_package_require_group() {
  local dir="$1" ext="$2" group="$3"
  if ! _package_valid_name "$group"; then
    _package_error "invalid package group name '$group'"
    return 1
  fi
  if [[ ! -f "$dir/$group$ext" ]]; then
    _package_error "unknown package group '$group' (available: $(package_group_names "$dir" "$ext" | _package_join))"
    return 1
  fi
}

# Resolve a profile plus additions and removals to an ordered group list.
# Usage: package_groups_resolve <dir> <ext> <profile> <with> <without>
# <with> and <without> are comma-separated group names and may be empty.
# Prints one group per line: the profile's groups in order, then additions.
package_groups_resolve() {
  local dir="$1" ext="$2" profile="$3" with="$4" without="$5"
  local base additions removals group selected=""

  base="$(package_profile_groups "$dir/profiles" "$profile")" || return 1
  additions="$(_package_split "$with")"
  removals="$(_package_split "$without")"

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    _package_require_group "$dir" "$ext" "$group" || return 1
    if [[ "$group" == "$PACKAGE_REQUIRED_GROUP" ]]; then
      _package_error "the $PACKAGE_REQUIRED_GROUP package group is required and cannot be removed"
      return 1
    fi
    if printf '%s\n' "$additions" | grep -Fxq -- "$group"; then
      _package_error "package group '$group' is both added and removed"
      return 1
    fi
  done <<EOF
$removals
EOF

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    _package_require_group "$dir" "$ext" "$group" || return 1
    if printf '%s\n' "$removals" "$selected" | grep -Fxq -- "$group"; then
      continue
    fi
    if [[ -n "$selected" ]]; then
      selected="$selected
$group"
    else
      selected="$group"
    fi
  done <<EOF
$base
$additions
EOF

  if ! printf '%s\n' "$selected" | grep -Fxq -- "$PACKAGE_REQUIRED_GROUP"; then
    _package_error "profile '$profile' must include the $PACKAGE_REQUIRED_GROUP package group"
    return 1
  fi
  printf '%s\n' "$selected"
}

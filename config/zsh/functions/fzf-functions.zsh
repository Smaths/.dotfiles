__fzf_require_cmd() {
  local cmd="${1:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    print -u2 "Missing required command: $cmd"
    return 127
  fi
}

__fzf_fd_excludes() {
  local exclude_source
  exclude_source="${FZF_FD_EXCLUDE_ARGS:---exclude .git --exclude node_modules --exclude .cache --exclude dist --exclude build --exclude .next --exclude .turbo --exclude coverage --exclude target}"
  print -r -- "$exclude_source"
}

__fzf_fd_find() {
  local type="${1:-f}"
  local root="${2:-.}"
  local exclude_source
  local -a exclude_args

  exclude_source="$(__fzf_fd_excludes)"
  exclude_args=(${=exclude_source})
  fd -H -a -t "$type" "${exclude_args[@]}" . "$root"
}

fcd() {
  local root selected
  root="${1:-.}"

  __fzf_require_cmd fzf || return $?
  __fzf_require_cmd fd || return $?
  [[ -d "$root" ]] || { print -u2 "Not a directory: $root"; return 1; }

  selected="$(
    __fzf_fd_find d "$root" |
      fzf \
        --prompt='dir> ' \
        --preview 'ls -la {} 2>/dev/null'
  )" || return 1

  [[ -n "$selected" ]] || return 1
  builtin cd -- "$selected"
}

ffcd() {
  local root selected
  root="${1:-.}"

  __fzf_require_cmd fzf || return $?
  __fzf_require_cmd fd || return $?
  [[ -d "$root" ]] || { print -u2 "Not a directory: $root"; return 1; }

  selected="$(
    __fzf_fd_find f "$root" |
      fzf \
        --prompt='file> ' \
        --preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || sed -n "1,200p" {}'
  )" || return 1

  [[ -n "$selected" ]] || return 1
  builtin cd -- "${selected:h}"
}

fview() {
  local root selected
  root="${1:-.}"

  __fzf_require_cmd fzf || return $?
  __fzf_require_cmd fd || return $?
  [[ -d "$root" ]] || { print -u2 "Not a directory: $root"; return 1; }

  selected="$(
    __fzf_fd_find f "$root" |
      fzf \
        --prompt='view> ' \
        --preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || sed -n "1,200p" {}'
  )" || return 1

  [[ -n "$selected" ]] || return 1

  if command -v bat >/dev/null 2>&1; then
    bat --style=numbers --color=always --line-range :200 "$selected"
  elif command -v less >/dev/null 2>&1 && [[ -t 1 ]]; then
    less -- "$selected"
  else
    sed -n '1,200p' "$selected"
  fi
}

fstack() {
  local line idx

  if [[ $# -gt 0 ]]; then
    idx="$1"
    [[ "$idx" == <-> ]] || { print -u2 "Usage: d [stack-index]"; return 2; }
    builtin cd "-$idx" >/dev/null
    return
  fi

  __fzf_require_cmd fzf || return $?

  line="$(
    dirs -v |
      fzf \
        --prompt='stack> ' \
        --preview 'echo {}' \
        --preview-window=hidden
  )" || return 1

  idx="${line%%[[:space:]]*}"
  [[ "$idx" == <-> ]] || return 1
  builtin cd "-$idx" >/dev/null
}

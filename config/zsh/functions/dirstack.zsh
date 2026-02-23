# Directory stack navigator (0-9)
d() {
  emulate -L zsh
  setopt localoptions

  # Show only 0..9
  dirs -v | sed -n '1,10p'

  local k="${1:-}"
  if [[ -z "$k" ]]; then
    print -n -- "Select [0-9]: "
    read -rk 1 k
    print
  fi

  [[ "$k" == [0-9] ]] || { print -u2 "$k is not a valid option."; return 1; }

  # Jump using zsh's built-in stack indexing (matches dirs -v)
  builtin cd "+$k" >/dev/null
}

# Keep numeric commands (0-9) as thin wrappers to the builtin cd +N, which is more efficient than parsing the output of dirs -v. This allows users to quickly jump to directories in their stack using a single digit.
for i in {0..9}; do
  eval "$i() { builtin cd '+$i' >/dev/null; }"
done
unset i
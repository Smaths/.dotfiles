#!/usr/bin/env zsh
set -eu

REPO_DIR="${0:A:h:h}"
TEST_TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-startup-test.XXXXXX")"
trap 'rm -rf -- "$TEST_TMP_ROOT"' EXIT INT TERM
export REPO_DIR TEST_TMP_ROOT
export HOME="$TEST_TMP_ROOT/home" ZDOTDIR="$TEST_TMP_ROOT/home" TERM=xterm-256color
mkdir -p "$HOME"

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

# Stub the emitted integration, not the terminal checks in the real module.
cat >"$TEST_TMP_ROOT/integration.zsh" <<'EOF'
fzf() {
  print called >> "$TEST_TMP_ROOT/fzf-called"
  print 'fzf-history-widget() { :; }; zle -N fzf-history-widget'
}
zoxide() { print 'z() { :; }'; }
ZSH_PLUGIN_DIR="$HOME/no-plugins"
source "$REPO_DIR/config/zsh/env.zsh"
source "$REPO_DIR/config/zsh/plugins.zsh"
source "$REPO_DIR/config/zsh/functions/fzf-functions.zsh"
[[ -n "$FZF_DEFAULT_COMMAND" && -n "$FZF_CTRL_T_COMMAND" ]] || exit 1
(( $+functions[fcd] && $+functions[z] )) || exit 1
print DONE
EOF

# Captured non-TTY -ic startup must remain quiet and retain non-ZLE config.
zsh -fic 'source "$TEST_TMP_ROOT/integration.zsh"' </dev/null >"$TEST_TMP_ROOT/out" 2>"$TEST_TMP_ROOT/err"
[[ "$(<"$TEST_TMP_ROOT/out")" == DONE && ! -s "$TEST_TMP_ROOT/err" ]] || fail 'non-TTY startup emitted unexpected output'
[[ ! -e "$TEST_TMP_ROOT/fzf-called" ]] || fail 'non-TTY startup ran fzf integration'

# Exercise an actual PTY, plus each redirected descriptor independently.
zmodload zsh/zpty
for mode in terminal stdin stdout dumb nozle; do
  case "$mode" in
    terminal) setup='' ;;
    stdin) setup='exec </dev/null;' ;;
    stdout) setup='exec >"$TEST_TMP_ROOT/redirected";' ;;
    dumb) setup='TERM=dumb;' ;;
    nozle) setup='unsetopt zle;' ;;
  esac
  rm -f "$TEST_TMP_ROOT/fzf-called"
  code="$setup source \"\$TEST_TMP_ROOT/integration.zsh\"; print -u2 FINISHED"
  # zpty forks this shell; do not inherit the parent's temporary-dir cleanup.
  zpty child "trap - EXIT INT TERM; zsh -fic ${(q)code}"
  result=''
  zpty -r child result '*FINISHED*'
  zpty -d child
  [[ "$result" != *"can't change option"* ]] || fail "ZLE error with $mode"
  if [[ "$mode" == terminal ]]; then
    [[ -f "$TEST_TMP_ROOT/fzf-called" ]] || fail 'terminal startup must enable fzf'
  else
    [[ ! -e "$TEST_TMP_ROOT/fzf-called" ]] || fail "fzf must be skipped with $mode"
  fi
done

# Instrument compaudit to prove it is invoked both before and after caching.
# A stub isolates this test from host fpath ownership/permissions.
zsh -fc '
  compaudit() { print audited >> "$TEST_TMP_ROOT/audit"; return 0; }
  ZSH_PLUGIN_DIR="$HOME/no-plugins"
  LS_COLORS=""
  source "$REPO_DIR/config/zsh/completion.zsh"
  [[ -f "$HOME/.zcompdump" ]] || exit 1
  # compinit unfunctions compaudit on completion; restore instrumentation.
  compaudit() { print audited >> "$TEST_TMP_ROOT/audit"; return 0; }
  source "$REPO_DIR/config/zsh/completion.zsh"
  [[ "$(wc -l < "$TEST_TMP_ROOT/audit")" -eq 2 ]]
' || fail 'compaudit must run even with a cached dump'

print 'ok - Zsh completion audit and terminal integration guards'

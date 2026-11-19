#!/usr/bin/env zsh
set -euo pipefail

# -----------------------------------------------------------------------------
# Dotfiles Bootstrap (macOS)
#
# Purpose:
# - Set up a fresh or existing macOS machine using this dotfiles repo.
# - Keep reruns safe (idempotent where possible, with backups before relinking).
#
# What this script does:
# 1) Validates runtime prerequisites and platform
# 2) Installs Homebrew if missing
# 3) Installs the package groups of the selected profile (default: full) from
#    packages/, adjusted by --with/--without, unless --skip-packages
# 4) Links config/mise/config.toml to the XDG path mise reads by default
# 5) Installs pinned Go, Node.js, Pi, and pnpm versions with mise
# 6) Links uv configuration for isolated Python management
# 7) Installs git via Homebrew when missing
# 8) Safely links ~/.zshrc and ~/.zprofile to this repo
# 9) Clones the Zsh plugins that config/zsh/plugins.zsh loads
# 10) Links the Ghostty, tmux, delta, and lazygit configs, and registers the
#     delta include in the user-owned ~/.gitconfig
# 11) With --macos-settings, applies the managed macOS defaults unattended
#
# Safety behavior:
# - Existing ~/.zshrc and ~/.zprofile are backed up with timestamp suffixes
#   before symlinks are replaced.
# - --dry-run prints commands and planned changes without modifying the system.
# -----------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SCRIPT_DIR="${0:A:h}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PACKAGES_DIR="$SCRIPT_DIR/packages"
SETTINGS_SCRIPT="$SCRIPT_DIR/settings.zsh"
MISE_CONFIG_TARGET="$DOTFILES_DIR/config/mise/config.toml"
MISE_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/mise/config.toml"
UV_CONFIG_TARGET="$DOTFILES_DIR/config/uv/uv.toml"
UV_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/uv/uv.toml"
ZSHRC_TARGET="$DOTFILES_DIR/config/zsh/.zshrc"
ZPROFILE_TARGET="$DOTFILES_DIR/config/zsh/.zprofile"
PROMPT_PURIFICATION_TARGET="$DOTFILES_DIR/config/zsh/prompts/purification/prompt_purification_setup"
GHOSTTY_CONFIG_TARGET="$DOTFILES_DIR/config/ghostty/config"
GHOSTTY_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/ghostty/config"
TMUX_CONFIG_TARGET="$DOTFILES_DIR/config/tmux/tmux.conf"
TMUX_CONFIG_LINK_PATH="$HOME/.tmux.conf"
GIT_DELTA_CONFIG_TARGET="$DOTFILES_DIR/config/git/delta.gitconfig"
GIT_DELTA_CONFIG_LINK_PATH="$XDG_CONFIG_HOME/git/delta.gitconfig"
# lazygit reads this path on macOS; confirm with `lazygit --print-config-dir`.
LAZYGIT_CONFIG_TARGET="$DOTFILES_DIR/config/lazygit/config.yml"
LAZYGIT_CONFIG_LINK_PATH="$HOME/Library/Application Support/lazygit/config.yml"
COMMON_LIB="$DOTFILES_DIR/install/lib/common.sh"
HOMEBREW_LIB="$DOTFILES_DIR/install/lib/homebrew.sh"
UI_LIB="$DOTFILES_DIR/install/lib/ui.sh"
ZSH_PLUGINS_LIB="$DOTFILES_DIR/install/lib/zsh-plugins.sh"
PACKAGES_LIB="$DOTFILES_DIR/install/lib/packages.sh"
DRY_RUN=0
YES=0
INSTALL_GIT=0
UPGRADE_PACKAGES=0
UPGRADE_PLUGINS=0
SKIP_PACKAGES=0
APPLY_SETTINGS=0
PROFILE=""
WITH_GROUPS=""
WITHOUT_GROUPS=""
VERBOSE=0
BREW_BIN=""
BREWFILE_PACKAGE_COUNT=0
SELECTED_GROUPS=()
SELECTED_BREWFILE=""
SELECTED_BREWFILE_DIR=""
GIT_INCLUDE_STATUS=""
ZSH_PLUGIN_ROOT=""
TOTAL_STEPS=12

usage() {
  cat <<'EOF'
Usage: bootstrap.zsh [options]

Options:
  --profile NAME       Package profile from packages/profiles: slim or full (default: full)
  --with GROUPS        Add comma-separated package groups, e.g. --with ai,creative
  --without GROUPS     Remove comma-separated package groups (core is required)
  --skip-packages      Install no packages; git and mise must already be installed
  --macos-settings     Apply the managed macOS defaults (Finder, Dock, trackpad)
  --dry-run            Print actions without changing anything
  --yes                Run without interactive confirmation
  --verbose            Show more command details
  --upgrade-packages   Upgrade outdated selected packages during bootstrap
  --upgrade-plugins    Fast-forward Zsh plugins to the manifest's pinned commits
  -h, --help           Show this help

Package groups live in packages/<group>.Brewfile.
EOF
}

append_groups() {
  # Repeated --with/--without flags accumulate into one comma-separated list.
  if [[ -n "$1" ]]; then
    printf '%s,%s' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}

set_option_value() {
  local option="$1" value="$2"
  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a value" >&2
    usage >&2
    exit 1
  fi
  case "$option" in
    --profile) PROFILE="$value" ;;
    --with) WITH_GROUPS="$(append_groups "$WITH_GROUPS" "$value")" ;;
    --without) WITHOUT_GROUPS="$(append_groups "$WITHOUT_GROUPS" "$value")" ;;
  esac
}

while (($# > 0)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) YES=1 ;;
    --verbose) VERBOSE=1 ;;
    --upgrade-packages) UPGRADE_PACKAGES=1 ;;
    --upgrade-plugins) UPGRADE_PLUGINS=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --macos-settings) APPLY_SETTINGS=1 ;;
    --profile=* | --with=* | --without=*)
      set_option_value "${1%%=*}" "${1#*=}"
      ;;
    --profile | --with | --without)
      if (($# < 2)); then
        set_option_value "$1" ""
      fi
      set_option_value "$1" "$2"
      shift
      ;;
    --creative)
      echo "ERROR: --creative was replaced by --with creative" >&2
      exit 1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if ((SKIP_PACKAGES)) && [[ -n "$PROFILE$WITH_GROUPS$WITHOUT_GROUPS" ]] || ((SKIP_PACKAGES && UPGRADE_PACKAGES)); then
  echo "ERROR: --skip-packages cannot be combined with --profile, --with, --without, or --upgrade-packages" >&2
  exit 1
fi
PROFILE="${PROFILE:-full}"

if ((APPLY_SETTINGS)); then
  TOTAL_STEPS=13
fi

if [[ ! -f "$COMMON_LIB" ]]; then
  printf 'ERROR: Missing shared bootstrap helper: %s\n' "$COMMON_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/common.sh
source "$COMMON_LIB"

on_error() {
  local exit_code="$1"
  local line_no="$2"
  local step="${UI_CURRENT_STEP_LABEL:-bootstrap}"

  # Ctrl+C / signal-driven exits can still trigger ERR in zsh.
  # Keep interrupt output clean and avoid a misleading failure line.
  if ((exit_code == 130 || exit_code == 143 || exit_code == -3)); then
    return 0
  fi

  echo
  echo "ERROR: $step failed at line $line_no (exit $exit_code)" >&2
}

resolve_brew_bin() {
  # Determine brew executable even when PATH is not initialized yet.
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo "/opt/homebrew/bin/brew"
    return 0
  fi
  if [[ -x /usr/local/bin/brew ]]; then
    echo "/usr/local/bin/brew"
    return 0
  fi
  return 1
}

count_brewfile_packages() {
  # Count active Brewfile dependency declarations for progress output.
  local brewfile="${1:?count_brewfile_packages requires a Brewfile path}"

  awk '
    /^[[:space:]]*(brew|cask|tap|mas|vscode|go|cargo|uv|npm)[[:space:]]/ { count++ }
    END { print count + 0 }
  ' "$brewfile"
}

register_git_include() {
  # ~/.gitconfig is not managed by this repo -- it carries per-machine identity
  # and signing settings. Bootstrap adds one include.path entry pointing at the
  # tracked delta config instead of owning that file. Sets GIT_INCLUDE_STATUS.
  local include_path="$1"
  local existing

  if ((DRY_RUN)); then
    printf '[dry-run] git config --global --add include.path %q (only when absent)\n' "$include_path"
    GIT_INCLUDE_STATUS="planned"
    return 0
  fi

  existing="$(git config --global --get-all include.path 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -Fxq "$include_path"; then
    GIT_INCLUDE_STATUS="present"
    return 0
  fi

  git config --global --add include.path "$include_path"
  GIT_INCLUDE_STATUS="added"
}

selected_groups_label() {
  printf '%s' "${(j:, :)SELECTED_GROUPS}"
}

print_preflight_plan() {
  echo
  echo "Bootstrap plan (macOS)"
  echo "----------------------"
  if [[ -n "$BREW_BIN" ]]; then
    echo "  Homebrew: already installed at $BREW_BIN"
  else
    echo "  Homebrew: install using the official installer"
  fi
  if ((SKIP_PACKAGES)); then
    echo "  Packages: skipped (--skip-packages); git and mise must already be installed"
  else
    echo "  Package profile: $PROFILE"
    echo "  Package groups: $(selected_groups_label)"
    if ((UPGRADE_PACKAGES)); then
      echo "  Packages: install missing entries and upgrade outdated entries"
    else
      echo "  Packages: install missing entries only"
    fi
  fi
  echo "  mise config link: $MISE_CONFIG_LINK_PATH"
  echo "  mise tools: install pinned Go, Node.js, Pi, and pnpm versions"
  echo "  uv config link: $UV_CONFIG_LINK_PATH"
  if ((SKIP_PACKAGES)); then
    echo "  Git: required; not installed by --skip-packages"
  else
    echo "  Git: install with Homebrew only if missing"
  fi
  echo "  Shell links: ~/.zshrc and ~/.zprofile"
  echo "  Zsh prompt: vendored Prompt Purification"
  if ((UPGRADE_PLUGINS)); then
    echo "  Zsh plugins: install missing pins and fast-forward existing clones to pins in $ZSH_PLUGIN_ROOT"
  else
    echo "  Zsh plugins: install missing pins and verify existing clones in $ZSH_PLUGIN_ROOT"
  fi
  if [[ -f "$GHOSTTY_CONFIG_TARGET" ]]; then
    echo "  Ghostty link: $GHOSTTY_CONFIG_LINK_PATH"
  else
    echo "  Ghostty link: skipped (target missing)"
  fi
  if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
    echo "  tmux link: $TMUX_CONFIG_LINK_PATH"
  else
    echo "  tmux link: skipped (target missing)"
  fi
  echo "  delta link: $GIT_DELTA_CONFIG_LINK_PATH"
  echo "  Git include: add include.path to ~/.gitconfig if absent (no other edits)"
  echo "  lazygit link: $LAZYGIT_CONFIG_LINK_PATH"
  if ((APPLY_SETTINGS)); then
    echo "  macOS settings: apply managed defaults; restarts Finder and Dock"
  else
    echo "  macOS settings: skipped (pass --macos-settings to apply)"
  fi
}

confirm_preflight() {
  local answer

  print_preflight_plan

  if ((DRY_RUN)); then
    echo
    echo "Dry run: continuing without confirmation."
    return 0
  fi

  if ((YES)); then
    echo
    echo "Proceeding because --yes was passed."
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo
    echo "ERROR: Refusing to run mutating bootstrap without an interactive terminal." >&2
    echo "Pass --yes to run non-interactively or --dry-run to inspect planned actions." >&2
    exit 1
  fi

  echo
  read -r "?Proceed with these changes? [y/N]: " answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      echo "Cancelled."
      exit 0
      ;;
  esac
}

show_brewfile_misses() {
  local brewfile="${1:?show_brewfile_misses requires a Brewfile path}"
  local label="${2:-Brewfile}"

  echo "  $label is not satisfied. Details:"
  if ((UPGRADE_PACKAGES)); then
    brew bundle check --verbose --file="$brewfile" || true
  else
    env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file="$brewfile" || true
  fi
}

if [[ ! -f "$UI_LIB" ]]; then
  echo "ERROR: Missing shared UI helper: $UI_LIB" >&2
  exit 1
fi
# shellcheck source=../lib/ui.sh
source "$UI_LIB"

if [[ ! -f "$HOMEBREW_LIB" ]]; then
  echo "ERROR: Missing Homebrew installer helper: $HOMEBREW_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/homebrew.sh
source "$HOMEBREW_LIB"

if [[ ! -f "$ZSH_PLUGINS_LIB" ]]; then
  echo "ERROR: Missing Zsh plugin helper: $ZSH_PLUGINS_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/zsh-plugins.sh
source "$ZSH_PLUGINS_LIB"
ZSH_PLUGIN_ROOT="$(zsh_plugin_root)"

if [[ ! -f "$PACKAGES_LIB" ]]; then
  echo "ERROR: Missing package group helper: $PACKAGES_LIB" >&2
  exit 1
fi
# shellcheck source=install/lib/packages.sh
source "$PACKAGES_LIB"

# Resolve package groups before any output or mutation so typos fail fast.
if ((! SKIP_PACKAGES)); then
  if [[ ! -d "$PACKAGES_DIR" ]]; then
    echo "ERROR: Package group directory not found at $PACKAGES_DIR" >&2
    exit 1
  fi
  _resolved_groups="$(package_groups_resolve "$PACKAGES_DIR" .Brewfile "$PROFILE" "$WITH_GROUPS" "$WITHOUT_GROUPS")" || exit 1
  SELECTED_GROUPS=("${(@f)_resolved_groups}")
  unset _resolved_groups
fi

build_selected_brewfile() {
  # Combine the selected groups into one temporary Brewfile so Homebrew checks
  # and installs the whole selection in a single, parallel pass.
  local group
  SELECTED_BREWFILE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-brewfile.XXXXXX")"
  SELECTED_BREWFILE="$SELECTED_BREWFILE_DIR/Brewfile"
  for group in "${SELECTED_GROUPS[@]}"; do
    printf '# --- %s (%s) ---\n' "$group" "$PACKAGES_DIR/$group.Brewfile"
    cat "$PACKAGES_DIR/$group.Brewfile"
    printf '\n'
  done >"$SELECTED_BREWFILE"
}

cleanup_selected_brewfile() {
  if [[ -n "$SELECTED_BREWFILE_DIR" && -d "$SELECTED_BREWFILE_DIR" ]]; then
    rm -rf -- "$SELECTED_BREWFILE_DIR"
  fi
}
trap cleanup_selected_brewfile EXIT

ui_init "snarfum dotfiles bootstrap" "$TOTAL_STEPS"
ui_print_header
ui_start
trap 'on_error $? $LINENO' ERR

# This bootstrap is intentionally macOS-only.
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: This bootstrap is intended for macOS (Darwin). Detected: $(uname -s)" >&2
  exit 1
fi

# Preflight requirements before network/package steps.
require_cmd uname "Install core system tools and retry."
require_cmd curl "curl is expected to be present on macOS. If it's missing, your PATH/environment is broken or the OS install is atypical. Fix PATH or reinstall base system tools and retry."

# Validate required project files before applying changes.
if ((APPLY_SETTINGS)) && [[ ! -f "$SETTINGS_SCRIPT" ]]; then
  echo "ERROR: macOS settings script not found at $SETTINGS_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$ZSHRC_TARGET" ]]; then
  echo "ERROR: Missing symlink target: $ZSHRC_TARGET" >&2
  exit 1
fi

if [[ ! -f "$ZPROFILE_TARGET" ]]; then
  echo "ERROR: Missing symlink target: $ZPROFILE_TARGET" >&2
  exit 1
fi

if [[ ! -f "$PROMPT_PURIFICATION_TARGET" ]]; then
  echo "ERROR: Missing vendored prompt: $PROMPT_PURIFICATION_TARGET" >&2
  exit 1
fi

if [[ ! -f "$MISE_CONFIG_TARGET" ]]; then
  echo "ERROR: Missing mise config: $MISE_CONFIG_TARGET" >&2
  exit 1
fi

if [[ ! -f "$UV_CONFIG_TARGET" ]]; then
  echo "ERROR: Missing uv config: $UV_CONFIG_TARGET" >&2
  exit 1
fi

if [[ ! -f "$GIT_DELTA_CONFIG_TARGET" ]]; then
  echo "ERROR: Missing delta git config: $GIT_DELTA_CONFIG_TARGET" >&2
  exit 1
fi

if [[ ! -f "$LAZYGIT_CONFIG_TARGET" ]]; then
  echo "ERROR: Missing lazygit config: $LAZYGIT_CONFIG_TARGET" >&2
  exit 1
fi

ui_step_start "Resolve Homebrew"
if BREW_BIN="$(resolve_brew_bin)"; then
  ui_step_ok "$BREW_BIN"
else
  ui_step_skip "not installed"
fi

confirm_preflight

# Install Homebrew if absent.
ui_step_start "Install Homebrew"
if [[ -z "$BREW_BIN" ]]; then
  if ((DRY_RUN)); then
    echo "[dry-run] download $HOMEBREW_INSTALL_URL to a temporary file and run it with /bin/bash"
  else
    echo "  running Homebrew installer in the foreground"
    install_homebrew
  fi
  if ! BREW_BIN="$(resolve_brew_bin)"; then
    if ((DRY_RUN)); then
      BREW_BIN="<homebrew path after install>"
    else
      echo "ERROR: Homebrew installer completed but brew could not be resolved." >&2
      exit 1
    fi
  fi
  ui_step_ok "$BREW_BIN"
else
  ui_step_skip "already installed"
fi

# Load brew into this shell so subsequent brew commands work immediately.
if [[ -n "$BREW_BIN" && "$BREW_BIN" != "<homebrew path after install>" ]]; then
  eval "$("$BREW_BIN" shellenv)"
fi

# If git is missing, install it after brew is available.
if ! command -v git >/dev/null 2>&1; then
  INSTALL_GIT=1
  if ((VERBOSE)); then
    echo "  git missing; will install"
  fi
fi

# --skip-packages leaves package selection to the user, so the tools the later
# steps run must already exist. Fail here, before any config is linked.
if ((SKIP_PACKAGES)); then
  for _required_cmd in git mise; do
    if ! command -v "$_required_cmd" >/dev/null 2>&1; then
      if ((DRY_RUN)); then
        echo "[dry-run] WARNING: $_required_cmd is missing; a real --skip-packages run would stop here"
      else
        require_cmd "$_required_cmd" "--skip-packages does not install packages; run 'brew install $_required_cmd' and retry."
      fi
    fi
  done
  unset _required_cmd
fi

if ((SKIP_PACKAGES)); then
  ui_step_start "Install packages"
  ui_step_skip "skipped (--skip-packages)"
else
  build_selected_brewfile
  BREWFILE_PACKAGE_COUNT="$(count_brewfile_packages "$SELECTED_BREWFILE")"
  ui_step_start "Install packages: $PROFILE profile (${BREWFILE_PACKAGE_COUNT})"
  if ((VERBOSE)); then
    echo "  groups: $(selected_groups_label)"
    echo "  combined Brewfile: $SELECTED_BREWFILE"
  fi
  if ((DRY_RUN)) && [[ "$BREW_BIN" == "<homebrew path after install>" ]]; then
    if ((UPGRADE_PACKAGES)); then
      echo "[dry-run] brew bundle install --verbose --file=\"$SELECTED_BREWFILE\" --jobs=auto"
    else
      echo "[dry-run] brew bundle install --verbose --file=\"$SELECTED_BREWFILE\" --no-upgrade --jobs=auto"
    fi
    ui_step_ok "planned after Homebrew install"
  else
    BREWFILE_READY=0
    if ((UPGRADE_PACKAGES)); then
      if brew bundle check --file="$SELECTED_BREWFILE" >/dev/null 2>&1; then
        BREWFILE_READY=1
      fi
    else
      if env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$SELECTED_BREWFILE" >/dev/null 2>&1; then
        BREWFILE_READY=1
      fi
    fi

    if ((BREWFILE_READY && ! INSTALL_GIT)); then
      if ((UPGRADE_PACKAGES)); then
        ui_step_skip "already installed/up to date"
      else
        ui_step_skip "already installed"
      fi
    else
      if ((! BREWFILE_READY)); then
        show_brewfile_misses "$SELECTED_BREWFILE" "Selected packages"
        echo "  installing selected packages with live Homebrew output (up to 4 parallel jobs)"
        if ((UPGRADE_PACKAGES)); then
          run_cmd brew bundle install --verbose --file="$SELECTED_BREWFILE" --jobs=auto
        else
          run_cmd brew bundle install --verbose --file="$SELECTED_BREWFILE" --no-upgrade --jobs=auto
        fi
      fi

      # Install git only when missing to keep reruns minimal.
      if ((INSTALL_GIT)); then
        run_cmd brew install git
      fi

      if ((DRY_RUN)); then
        ui_step_ok "planned"
      else
        ui_step_ok "brew bundle complete"
      fi
    fi
  fi
fi

# Link the tracked mise config to the path mise reads by default. Managed login
# shells expose its shims; unrelated GUI processes may not inherit that PATH.
ui_step_start "Link mise config"
run_cmd mkdir -p "${MISE_CONFIG_LINK_PATH:h}"
link_with_backup "$MISE_CONFIG_TARGET" "$MISE_CONFIG_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

ui_step_start "Install mise tools"
if ((! DRY_RUN)) && ! command -v mise >/dev/null 2>&1; then
  echo "ERROR: mise is not installed; install it with Homebrew and retry." >&2
  exit 1
fi
run_cmd mise install --yes
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "Go, Node.js, Pi, and pnpm installed/verified"
fi

ui_step_start "Link uv config"
run_cmd mkdir -p "${UV_CONFIG_LINK_PATH:h}"
link_with_backup "$UV_CONFIG_TARGET" "$UV_CONFIG_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

ui_step_start "Link shell config files"
link_with_backup "$ZSHRC_TARGET" "$HOME/.zshrc"
link_with_backup "$ZPROFILE_TARGET" "$HOME/.zprofile"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

# Package upgrades never advance plugin code. Only --upgrade-plugins permits
# fast-forwarding existing clones to the reviewed manifest pins.
ui_step_start "Install Zsh plugins ($(zsh_plugin_count))"
require_cmd git "git is required to clone the Zsh plugins."
sync_zsh_plugins "$ZSH_PLUGIN_ROOT" "$UPGRADE_PLUGINS"
if ((DRY_RUN)); then
  ui_step_ok "planned"
elif ((ZSH_PLUGINS_UNMANAGED > 0 || ZSH_PLUGINS_PENDING > 0)); then
  ui_step_ok "$ZSH_PLUGINS_CLONED cloned, $ZSH_PLUGINS_UNMANAGED unmanaged, $ZSH_PLUGINS_PENDING pending pins"
elif ((ZSH_PLUGINS_CLONED > 0 || ZSH_PLUGINS_UPDATED > 0)); then
  ui_step_ok "$ZSH_PLUGINS_CLONED cloned, $ZSH_PLUGINS_UPDATED updated"
else
  ui_step_skip "verified at pinned commits"
fi

# Link Ghostty config to XDG default path when present.
ui_step_start "Link Ghostty config"
if [[ -f "$GHOSTTY_CONFIG_TARGET" ]]; then
  run_cmd mkdir -p "$XDG_CONFIG_HOME/ghostty"
  link_with_backup "$GHOSTTY_CONFIG_TARGET" "$GHOSTTY_CONFIG_LINK_PATH"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "linked/verified"
  fi
else
  ui_step_skip "target missing"
fi

# Link tmux config to ~/.tmux.conf when present.
ui_step_start "Link tmux config"
if [[ -f "$TMUX_CONFIG_TARGET" ]]; then
  link_with_backup "$TMUX_CONFIG_TARGET" "$TMUX_CONFIG_LINK_PATH"
  if ((DRY_RUN)); then
    ui_step_ok "planned"
  else
    ui_step_ok "linked/verified"
  fi
else
  ui_step_skip "target missing"
fi

# Link the tracked delta config and include it from the user-owned ~/.gitconfig.
# The include is the only write this bootstrap makes to that file.
ui_step_start "Link Git delta config"
run_cmd mkdir -p "${GIT_DELTA_CONFIG_LINK_PATH:h}"
link_with_backup "$GIT_DELTA_CONFIG_TARGET" "$GIT_DELTA_CONFIG_LINK_PATH"
register_git_include "$GIT_DELTA_CONFIG_LINK_PATH"
case "$GIT_INCLUDE_STATUS" in
  planned) ui_step_ok "planned" ;;
  added) ui_step_ok "linked; include.path added to ~/.gitconfig" ;;
  *) ui_step_ok "linked; include.path already present" ;;
esac

# lazygit does not read git's core.pager, so it gets delta through its own config.
ui_step_start "Link lazygit config"
run_cmd mkdir -p "${LAZYGIT_CONFIG_LINK_PATH:h}"
link_with_backup "$LAZYGIT_CONFIG_TARGET" "$LAZYGIT_CONFIG_LINK_PATH"
if ((DRY_RUN)); then
  ui_step_ok "planned"
else
  ui_step_ok "linked/verified"
fi

if ((APPLY_SETTINGS)); then
  ui_step_start "Apply macOS settings"
  if ((DRY_RUN)); then
    zsh "$SETTINGS_SCRIPT" --yes --dry-run
    ui_step_ok "planned"
  else
    zsh "$SETTINGS_SCRIPT" --yes
    ui_step_ok "applied"
  fi
fi

ui_summary
echo "Optional local overrides:"
echo "  cp ~/.dotfiles/config/zsh/local.example.zsh ~/.dotfiles/config/zsh/local.zsh"
echo "  Example: add aliases, PATH entries, or machine-specific env vars to local.zsh"
echo "           alias work='cd ~/code/work'"

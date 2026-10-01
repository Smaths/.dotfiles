# Collidascope VPS
# Override CSK_* values in config/zsh/local.zsh for machine-specific settings.
: "${CSK_VPS_USER:=eric}"
export CSK_VPS_USER
: "${CSK_VPS_HOST:=csk-server-eric}"
export CSK_VPS_HOST
: "${CSK_LOCAL_SERVER_OWNER:=csk-ops:csk-ops}"
if [[ "$CSK_LOCAL_SERVER_OWNER" == csk-server-*:csk-server-* ]]; then
  CSK_LOCAL_SERVER_OWNER="csk-ops:csk-ops"
fi
export CSK_LOCAL_SERVER_OWNER
: "${CSK_REPO_ROOT:=$HOME/Developer/CollidascopeVR/CollidascopeStudio}"
export CSK_REPO_ROOT
# Follows CSK_REPO_ROOT so overriding the repo path also moves the build dir.
: "${LINUX_SERVER_BUILD_DIR:=$CSK_REPO_ROOT/Builds/ServerLinux64}"
export LINUX_SERVER_BUILD_DIR
: "${CSK_UNITY_HUB_EDITOR_ROOT:=/Applications/Unity/Hub/Editor}"
export CSK_UNITY_HUB_EDITOR_ROOT

# Editor version comes from ProjectSettings/ProjectVersion.txt so the build
# alias cannot drift from the version the project actually requires.
# Set CSK_UNITY_BIN to bypass resolution entirely.
_csk-unity-bin() {
  if [[ -n "${CSK_UNITY_BIN:-}" ]]; then
    if [[ ! -x "$CSK_UNITY_BIN" ]]; then
      echo "CSK_UNITY_BIN is set but not executable: $CSK_UNITY_BIN" >&2
      return 1
    fi
    print -r -- "$CSK_UNITY_BIN"
    return 0
  fi

  local version_file="$CSK_REPO_ROOT/ProjectSettings/ProjectVersion.txt"
  if [[ ! -f "$version_file" ]]; then
    echo "ProjectVersion.txt not found: $version_file" >&2
    echo "Set CSK_REPO_ROOT to the Collidascope Studio repo root." >&2
    return 1
  fi

  local version
  version="$(awk '/^m_EditorVersion:/ { print $2; exit }' "$version_file")"
  if [[ -z "$version" ]]; then
    echo "Could not read m_EditorVersion from $version_file" >&2
    return 1
  fi

  local unity_bin="$CSK_UNITY_HUB_EDITOR_ROOT/$version/Unity.app/Contents/MacOS/Unity"
  if [[ ! -x "$unity_bin" ]]; then
    echo "Unity $version is not installed at $unity_bin" >&2
    echo "Install $version through Unity Hub, or set CSK_UNITY_BIN." >&2
    return 1
  fi

  print -r -- "$unity_bin"
}

# True when a non-batchmode Unity editor appears to hold this project open.
# AGENTS.md and the Linux server runbook forbid batchmode while the editor is
# open. A stale Temp/UnityLockfile alone is not treated as proof.
_csk-unity-editor-open() {
  local project="${1:-$CSK_REPO_ROOT}"
  local pids pid args
  pids=(${(f)"$(pgrep -f '/Unity.app/Contents/MacOS/Unity' 2>/dev/null)"})
  ((${#pids})) || return 1

  for pid in $pids; do
    args="$(ps -o command= -p "$pid" 2>/dev/null)"
    [[ -n "$args" ]] || continue
    [[ "$args" == *-batchmode* ]] && continue
    [[ "$args" == *"$project"* ]] && return 0
    # An editor with no visible -projectPath could be this project; be strict.
    [[ "$args" != *-projectPath* ]] && return 0
  done

  return 1
}

csk-build-linux-server() {
  local unity_bin
  unity_bin="$(_csk-unity-bin)" || return 1

  if _csk-unity-editor-open; then
    echo "A Unity editor appears to have $CSK_REPO_ROOT open." >&2
    echo "Close it before running a batchmode build (see Docs/Development/UnityVerification.md)." >&2
    echo "Set CSK_FORCE_BATCHMODE=1 to override." >&2
    [[ "${CSK_FORCE_BATCHMODE:-}" == "1" ]] || return 1
  fi

  local log_file="${CSK_BUILD_LOG:-/tmp/collidascope-linux-server-build.log}"
  echo "Unity:   $unity_bin"
  echo "Project: $CSK_REPO_ROOT"
  echo "Log:     $log_file"

  "$unity_bin" \
    -batchmode \
    -nographics \
    -quit \
    -projectPath "$CSK_REPO_ROOT" \
    -executeMethod CSK.Editor.Build.CIServerBuild.BuildLinux \
    -logFile "$log_file"

  local status=$?
  if ((status != 0)); then
    echo "Build failed (exit $status). Last 40 log lines:" >&2
    tail -n 40 "$log_file" >&2
    return $status
  fi

  local artifact
  artifact="$(_csk-latest-linux-artifact)" || return 1
  echo "Build succeeded: $artifact"
}

_csk-latest-linux-artifact() {
  local -a artifacts
  artifacts=("$LINUX_SERVER_BUILD_DIR"/*.tar.gz(N.om[1]))
  if ((${#artifacts} == 0)); then
    echo "No Linux server artifact found in $LINUX_SERVER_BUILD_DIR" >&2
    return 1
  fi
  print -r -- "$artifacts[1]"
}

# Fails before upload when the archive does not match the Linux release
# contract, and reports the version being shipped so a stale artifact is
# visible rather than silently deployed.
_csk-describe-linux-artifact() {
  local artifact="$1"
  local listing
  listing="$(tar -tzf "$artifact" 2>/dev/null)" || {
    echo "Could not read archive: $artifact" >&2
    return 1
  }

  local normalized
  normalized="$(print -r -- "$listing" | sed 's|^\./||')"

  local entry
  for entry in Collidascope UnityPlayer.so; do
    if ! print -r -- "$normalized" | grep -qx -- "$entry"; then
      echo "Archive is missing required file '$entry': $artifact" >&2
      return 1
    fi
  done
  if ! print -r -- "$normalized" | grep -q '^Collidascope_Data/'; then
    echo "Archive is missing required directory 'Collidascope_Data/': $artifact" >&2
    return 1
  fi

  echo "Artifact: $artifact"
  echo "Size:     $(du -h "$artifact" | cut -f1)"
  echo "Built:    $(date -r "$artifact" '+%Y-%m-%d %H:%M')"

  local build_info
  build_info="$(tar -xzOf "$artifact" ./BuildInfo.json 2>/dev/null || tar -xzOf "$artifact" BuildInfo.json 2>/dev/null)"
  if [[ -n "$build_info" ]]; then
    local version build_id channel
    version="$(print -r -- "$build_info" | awk -F'"' '/"version"/ { print $4; exit }')"
    build_id="$(print -r -- "$build_info" | awk -F'"' '/"buildId"/ { print $4; exit }')"
    channel="$(print -r -- "$build_info" | awk -F'"' '/"channel"/ { print $4; exit }')"
    echo "Version:  ${version:-unknown} buildId=${build_id:-unknown} channel=${channel:-unknown}"
  else
    echo "Version:  BuildInfo.json not present in archive"
  fi
}

_csk-deploy-linux-server-to() {
  local remote="$1"
  local release_owner="${2:-csk-server:csk-server}"
  local service_name="${3:-collidascope-server}"
  local artifact
  local release
  local remote_artifact

  artifact="$(_csk-latest-linux-artifact)" || return 1
  release="$(date +%Y%m%d-%H%M%S)"
  remote_artifact="/tmp/collidascope-server-$release.tar.gz"

  if [[ ! "$release_owner" =~ '^[A-Za-z_][A-Za-z0-9_-]*(:[A-Za-z_][A-Za-z0-9_-]*)?$' ]]; then
    echo "Invalid release owner: $release_owner"
    return 1
  fi

  if [[ ! "$service_name" =~ '^[A-Za-z0-9_.@-]+$' ]]; then
    echo "Invalid service name: $service_name"
    return 1
  fi

  _csk-describe-linux-artifact "$artifact" || return 1
  echo "Deploying to $remote as release $release..."

  scp "$artifact" "$remote:$remote_artifact" || return 1

  ssh -tt "$remote" "
    set -e
    sudo mkdir -p /opt/collidascope/server/releases/$release
    sudo tar -xzf $remote_artifact -C /opt/collidascope/server/releases/$release
    sudo chown -R $release_owner /opt/collidascope/server/releases/$release
    sudo chmod +x /opt/collidascope/server/releases/$release/Collidascope
    sudo ln -sfn /opt/collidascope/server/releases/$release /opt/collidascope/server/current
    sudo rm -f $remote_artifact
    sudo systemctl restart $service_name
    sudo systemctl --no-pager status $service_name
  " || return 1

  echo "Deploy complete."
}

csk-deploy-linux-server() {
  _csk-deploy-linux-server-to "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk-server:csk-server" "collidascope-server"
}

csk-deploy-linux-server-local() {
  local remote="csk-server-local"
  local release_owner="${CSK_LOCAL_SERVER_OWNER}"
  local artifact
  local release
  local remote_artifact

  artifact="$(_csk-latest-linux-artifact)" || return 1
  release="$(date +%Y%m%d-%H%M%S)"
  remote_artifact="/tmp/collidascope-server-$release.tar.gz"

  if [[ ! "$release_owner" =~ '^[A-Za-z_][A-Za-z0-9_-]*(:[A-Za-z_][A-Za-z0-9_-]*)?$' ]]; then
    echo "Invalid release owner: $release_owner"
    return 1
  fi

  _csk-describe-linux-artifact "$artifact" || return 1
  echo "Deploying to $remote as release $release..."

  scp "$artifact" "$remote:$remote_artifact" || return 1

  ssh -tt "$remote" "
    set -e
    sudo mkdir -p /opt/collidascope/server/releases/$release
    sudo tar -xzf $remote_artifact -C /opt/collidascope/server/releases/$release
    sudo chown -R $release_owner /opt/collidascope/server/releases/$release
    sudo chmod +x /opt/collidascope/server/releases/$release/Collidascope
    sudo ln -sfn /opt/collidascope/server/releases/$release /opt/collidascope/server/current
    sudo rm -f $remote_artifact
    cd /opt/collidascope/server
    docker compose -f compose.server.yaml up -d --force-recreate collidascope-server
    docker compose -f compose.server.yaml ps
  " || return 1

  echo "Deploy complete."
}

csk-sync-server-helpers() {
  local sync_script="${CSK_REPO_ROOT}/Ops/Hetzner/sync-server-helpers.sh"

  if [[ ! -x "$sync_script" ]]; then
    echo "Sync helper script not found or not executable: $sync_script"
    return 1
  fi

  CSK_VPS_USER="${CSK_VPS_USER}" CSK_VPS_HOST="${CSK_VPS_HOST}" \
    "$sync_script"
}

csk-sync-server-service() {
  local sync_script="${CSK_REPO_ROOT}/Ops/Hetzner/sync-server-service.sh"

  if [[ ! -x "$sync_script" ]]; then
    echo "Sync service script not found or not executable: $sync_script"
    return 1
  fi

  CSK_VPS_USER="${CSK_VPS_USER}" CSK_VPS_HOST="${CSK_VPS_HOST}" \
    "$sync_script"
}

# Reports whether /usr/local/bin/csk on the VPS still matches Ops/Hetzner/csk.
csk-check-server-helpers() {
  local local_csk="${CSK_REPO_ROOT}/Ops/Hetzner/csk"
  if [[ ! -f "$local_csk" ]]; then
    echo "Local csk helper not found: $local_csk" >&2
    return 1
  fi

  local local_sum remote_sum
  local_sum="$(shasum -a 256 "$local_csk" | awk '{ print $1 }')"
  remote_sum="$(ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" 'sha256sum /usr/local/bin/csk 2>/dev/null | cut -d" " -f1')" || return 1

  if [[ "$local_sum" == "$remote_sum" ]]; then
    echo "VPS csk helper matches Ops/Hetzner/csk."
    return 0
  fi

  echo "VPS csk helper differs from Ops/Hetzner/csk. Run: csk-sync-server-helpers"
  return 1
}

# Remote entry points. These follow CSK_VPS_USER/CSK_VPS_HOST rather than
# hardcoding the ssh config alias, and forward any extra arguments.
csk-ssh() { ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" "$@"; }
csk-server-status() { ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk service status"; }
csk-server-logs() { ssh -t "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk logs ${*}"; }
csk-server-unity-status() { ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk unity status"; }
csk-server-release() { ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk release current"; }
csk-server-port() { ssh "${CSK_VPS_USER}@${CSK_VPS_HOST}" "csk net port"; }

alias csk-deploy-local='csk-deploy-linux-server-local'
alias csk-ssh-local='ssh csk-server-local'
alias csk-server-status-local='ssh csk-server-local "cd /opt/collidascope/server && docker compose -f compose.server.yaml ps"'
alias csk-server-logs-local='ssh csk-server-local "docker logs -f collidascope-server"'
alias csk-server-unity-status-local='ssh csk-server-local "printf '\''{\"command\":\"status\"}\\n'\'' | nc 127.0.0.1 7788"'

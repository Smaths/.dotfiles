# Collidascope VPS
# Override CSK_* values in config/zsh/local.zsh for machine-specific settings.
: "${CSK_VPS_USER:=eric}"
export CSK_VPS_USER
: "${CSK_VPS_HOST:=5.161.181.25}"
export CSK_VPS_HOST
: "${CSK_REPO_ROOT:=$HOME/Developer/CollidascopeVR/CollidascopeStudio}"
export CSK_REPO_ROOT
: "${LINUX_SERVER_BUILD_DIR:=$HOME/Developer/CollidascopeVR/CollidascopeStudio/Builds/ServerLinux64}"
export LINUX_SERVER_BUILD_DIR

csk-build-linux-server() {
  local unity_bin="/Applications/Unity/Hub/Editor/6000.0.60f1/Unity.app/Contents/MacOS/Unity"

  if [[ ! -x "$unity_bin" ]]; then
    echo "Unity binary not found or not executable at $unity_bin"
    return 1
  fi

  "$unity_bin" \
    -batchmode \
    -nographics \
    -quit \
    -projectPath "$CSK_REPO_ROOT" \
    -executeMethod CSK.Editor.Build.CIServerBuild.BuildLinux
}

csk-deploy-linux-server() {
  local remote="${CSK_VPS_USER}@${CSK_VPS_HOST}"
  local artifact
  local release
  local remote_artifact

  artifact="$(ls -t "$LINUX_SERVER_BUILD_DIR"/*.tar.gz 2>/dev/null | head -n 1)"
  release="$(date +%Y%m%d-%H%M%S)"
  remote_artifact="/tmp/collidascope-server-$release.tar.gz"

  if [ -z "$artifact" ]; then
    echo "No Linux server artifact found in $LINUX_SERVER_BUILD_DIR"
    return 1
  fi

  echo "Deploying $artifact to $remote as release $release..."

  scp "$artifact" "$remote:$remote_artifact" || return 1

  ssh -tt "$remote" "
    set -e
    sudo mkdir -p /opt/collidascope/server/releases/$release
    sudo tar -xzf $remote_artifact -C /opt/collidascope/server/releases/$release
    sudo chown -R csk-server:csk-server /opt/collidascope/server/releases/$release
    sudo chmod +x /opt/collidascope/server/releases/$release/Collidascope
    sudo ln -sfn /opt/collidascope/server/releases/$release /opt/collidascope/server/current
    sudo rm -f $remote_artifact
    sudo systemctl restart collidascope-server
    sudo systemctl --no-pager status collidascope-server
  "

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

alias csk-ssh='ssh csk-server-eric'
alias csk-server-status='ssh csk-server-eric "csk service status"'
alias csk-server-logs='ssh csk-server-eric "csk logs"'
alias csk-server-unity-status='ssh csk-server-eric "csk unity status"'

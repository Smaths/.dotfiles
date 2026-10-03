#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Windows bootstrap manages host applications only. Shell tooling belongs in WSL.
$ScriptDir = Split-Path -Parent $PSCommandPath
$WingetManifest = Join-Path $ScriptDir "winget-packages.txt"
$DryRun = $false
$SkipPackages = $false
$Yes = $false
$VerboseOutput = $false
$TotalSteps = 4
$CurrentStep = 0
$OkCount = 0
$SkipCount = 0
$StartTime = Get-Date

function Show-Usage {
  @"
Usage: bootstrap-windows.ps1 [options]

Options:
  --dry-run         Print the package plan without changing anything
  --yes             Confirm package installation (required for noninteractive runs)
  --verbose         Show more command details
  --skip-packages   Skip winget package installation
  -h, --help        Show this help
"@
}

foreach ($arg in $args) {
  switch ($arg) {
    "--dry-run" { $DryRun = $true }
    "--verbose" { $VerboseOutput = $true }
    "--skip-packages" { $SkipPackages = $true }
    "--yes" { $Yes = $true }
    "--link-windows-shell" { throw "--link-windows-shell was removed; Windows Zsh linking is not managed. Use WSL guidance instead." }
    "--help" { Show-Usage; exit 0 }
    "-h" { Show-Usage; exit 0 }
    default { throw "Unknown option: $arg`n$(Show-Usage)" }
  }
}

function Write-Info { param([string]$Message) Write-Host $Message }
function Write-VerboseLine { param([string]$Message) if ($VerboseOutput) { Write-Info $Message } }
function Step-Start { param([string]$Label) $script:CurrentStep += 1; $script:CurrentStepLabel = $Label }
function Step-Ok { param([string]$Detail) $script:OkCount += 1; Write-Info ("[{0}/{1}] {2,-28} [OK] {3}" -f $CurrentStep, $TotalSteps, $CurrentStepLabel, $Detail) }
function Step-Skip { param([string]$Detail) $script:SkipCount += 1; Write-Info ("[{0}/{1}] {2,-28} [SKIP] {3}" -f $CurrentStep, $TotalSteps, $CurrentStepLabel, $Detail) }

function Resolve-WingetBin {
  $command = Get-Command winget -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  return $null
}

function Get-WingetPackageIds {
  param([Parameter(Mandatory = $true)][string]$ManifestPath)
  if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { throw "Winget manifest not found at $ManifestPath" }
  $ids = @()
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $id = $line.Trim()
    if (-not $id -or $id.StartsWith("#")) { continue }
    if ($id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw "Invalid winget package ID in manifest: '$id'" }
    $ids += $id
  }
  return ,$ids
}

function Get-WingetInstalledState {
  param([Parameter(Mandatory = $true)][string]$WingetPath, [Parameter(Mandatory = $true)][string]$PackageId)
  $output = (& $WingetPath "list" "--id" $PackageId "-e" "--accept-source-agreements" 2>&1 | Out-String)
  $exitCode = $LASTEXITCODE
  # winget reports an exact-ID miss with APPINSTALLER_CLI_ERROR_NO_APPLICATIONS_FOUND.
  # PowerShell can expose the HRESULT as either its signed or unsigned value.
  if ($exitCode -eq -1978335212 -or $exitCode -eq 2316632084) { return $false }
  if ($exitCode -ne 0) { throw "winget list failed for '$PackageId' (exit $exitCode): $output" }
  # The package ID column is stable across localized winget output; avoid matching localized prose.
  $escapedId = [regex]::Escape($PackageId)
  if ($output -match "(?im)^.*\s+$escapedId(?:\s|$)") { return $true }
  return $false
}

function Confirm-PackagePlan {
  param([string[]]$PackageIds)
  Write-Info "Windows host application plan ($($PackageIds.Count) missing package(s)):"
  foreach ($id in $PackageIds) { Write-Info "  $id" }
  if ($DryRun -or $PackageIds.Count -eq 0) { return $false }
  if ($Yes) { return $true }
  if ([Console]::IsInputRedirected) { throw "Refusing package installation without an interactive console; rerun with --yes to confirm." }
  $answer = Read-Host "Install these packages? [y/N]"
  if ($answer -notmatch '^(?i)y(es)?$') { return $false }
  return $true
}

Write-Info "dotfiles bootstrap (Windows)"
Write-Info ""
$isWindowsRuntime = $false
if (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) { $isWindowsRuntime = [bool]$IsWindows }
elseif ($env:OS -eq "Windows_NT") { $isWindowsRuntime = $true }
if (-not $isWindowsRuntime) { throw "This bootstrap is intended for Windows." }

Step-Start "Resolve winget"
$WingetBin = Resolve-WingetBin
if (-not $SkipPackages -and -not $WingetBin) { throw "winget not found; use --skip-packages to continue without host applications." }
if ($SkipPackages) { Step-Skip "skipped (--skip-packages)" } else { Step-Ok $WingetBin }

Step-Start "Preflight package plan"
$missingPackageIds = @()
if ($SkipPackages) {
  Step-Skip "skipped"
} else {
  $packageIds = Get-WingetPackageIds -ManifestPath $WingetManifest
  foreach ($packageId in $packageIds) {
    if (Get-WingetInstalledState -WingetPath $WingetBin -PackageId $packageId) {
      Write-VerboseLine "  already installed: $packageId"
    } else { $missingPackageIds += $packageId }
  }
  $shouldInstall = Confirm-PackagePlan -PackageIds $missingPackageIds
  Step-Ok ("{0} missing, {1} already installed" -f $missingPackageIds.Count, ($packageIds.Count - $missingPackageIds.Count))
}

Step-Start "Install host applications"
if ($SkipPackages -or $DryRun -or -not $shouldInstall -or $missingPackageIds.Count -eq 0) {
  Step-Skip $(if ($DryRun) { "dry-run; no packages installed" } elseif ($SkipPackages) { "skipped" } elseif (-not $shouldInstall) { "not confirmed" } else { "nothing missing" })
} else {
  $installedCount = 0
  foreach ($packageId in $missingPackageIds) {
    $output = (& $WingetBin "install" "--id" $packageId "-e" "--silent" "--accept-package-agreements" "--accept-source-agreements" 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { throw "winget install failed for '$packageId' (exit $exitCode): $output" }
    $installedCount++
  }
  Step-Ok ("{0} installed, {1} skipped as already installed" -f $installedCount, ($packageIds.Count - $missingPackageIds.Count))
}

Step-Start "Show WSL guidance"
$wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
$wslDistros = @()
if ($wslCommand) {
  $wslOutput = (& $wslCommand.Source "-l" "-q" 2>$null)
  $wslExit = $LASTEXITCODE
  if ($wslExit -eq 0 -and $null -ne $wslOutput) { $wslDistros = @($wslOutput | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
}
# A missing distro is an expected state, not the bootstrap's exit status.
$global:LASTEXITCODE = 0
if ($wslDistros.Count -eq 0) {
  Write-Info "No WSL distro detected. Install Ubuntu with: wsl --install -d Ubuntu"
  Step-Skip "no WSL distro detected"
} else {
  Write-Info "Detected WSL distro(s): $($wslDistros -join ', ')"
  Write-Info "In Debian/Ubuntu WSL, clone this repo inside the Linux filesystem (not /mnt/c), then run:"
  Write-Info "  git clone <repository-url> ~/.dotfiles"
  Write-Info "  sh ~/.dotfiles/install/bootstrap.sh --dry-run"
  Write-Info "  sh ~/.dotfiles/install/bootstrap.sh"
  Write-Info "The supported WSL setup is Bash/tmux; native Windows Zsh links are not managed."
  Step-Ok "printed supported WSL bootstrap guidance"
}

$elapsedSeconds = [int]((Get-Date) - $StartTime).TotalSeconds
Write-Info ""
Write-Info ("Completed in {0}s  |  {1} succeeded  |  {2} skipped" -f $elapsedSeconds, $OkCount, $SkipCount)

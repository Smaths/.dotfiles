#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Dotfiles Bootstrap (Windows)
#
# Purpose:
# - Set up a fresh or existing Windows machine using this dotfiles repo.
# - Keep reruns safe (idempotent where possible, with backups before relinking).
#
# What this script does:
# 1) Validates runtime platform
# 2) Resolves winget
# 3) Optionally installs packages from install/winget-packages.txt
# 4) Safely links ~/.zshrc and ~/.zprofile to this repo
#
# Safety behavior:
# - Existing ~/.zshrc and ~/.zprofile are backed up with timestamp suffixes
#   before symlinks are replaced.
# - --dry-run prints commands and planned changes without modifying the system.
# -----------------------------------------------------------------------------

$DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { Join-Path $HOME ".dotfiles" }
$WingetManifest = Join-Path $DotfilesDir "install/winget-packages.txt"
$ZshrcTarget = Join-Path $DotfilesDir "config/zsh/.zshrc"
$ZprofileTarget = Join-Path $DotfilesDir "config/zsh/.zprofile"
$HomePath = [Environment]::GetFolderPath("UserProfile")

$DryRun = $false
$SkipPackages = $false
$VerboseOutput = $false
$TotalSteps = 5
$CurrentStep = 0
$CurrentStepLabel = ""
$OkCount = 0
$SkipCount = 0
$StartTime = Get-Date

function Show-Usage {
  @"
Usage: bootstrap-windows.ps1 [options]

Options:
  --dry-run         Print actions without changing anything
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
    "--help" {
      Show-Usage
      exit 0
    }
    "-h" {
      Show-Usage
      exit 0
    }
    default {
      Write-Error "Unknown option: $arg"
      Show-Usage
      exit 1
    }
  }
}

function Write-Info {
  param([string]$Message)
  Write-Host $Message
}

function Write-VerboseLine {
  param([string]$Message)
  if ($VerboseOutput) {
    Write-Info $Message
  }
}

function Step-Start {
  param([string]$Label)
  $script:CurrentStep += 1
  $script:CurrentStepLabel = $Label
}

function Step-Ok {
  param([string]$Detail)
  $script:OkCount += 1
  Write-Info ("[{0}/{1}] {2,-28} [OK] {3}" -f $CurrentStep, $TotalSteps, $CurrentStepLabel, $Detail)
}

function Step-Skip {
  param([string]$Detail)
  $script:SkipCount += 1
  Write-Info ("[{0}/{1}] {2,-28} [SKIP] {3}" -f $CurrentStep, $TotalSteps, $CurrentStepLabel, $Detail)
}

function Invoke-ManagedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Display,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )

  if ($DryRun) {
    Write-Info "[dry-run] $Display"
    return
  }

  & $Command
}

function Resolve-WingetBin {
  $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
  if ($wingetCommand) {
    return $wingetCommand.Source
  }
  return $null
}

function Get-WingetPackageIds {
  param([Parameter(Mandatory = $true)][string]$ManifestPath)

  $ids = @()
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }
    if ($trimmed.StartsWith("#")) {
      continue
    }
    $ids += $trimmed
  }

  return $ids
}

function Resolve-NormalizedPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  try {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
  } catch {
    return $null
  }
}

function Test-IsAdministrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DeveloperModeEnabled {
  try {
    $keyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    $value = (Get-ItemProperty -LiteralPath $keyPath -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction Stop).AllowDevelopmentWithoutDevLicense
    return ($value -eq 1)
  } catch {
    return $false
  }
}

function Assert-SymlinkCapability {
  $isAdmin = Test-IsAdministrator
  $developerModeEnabled = Test-DeveloperModeEnabled
  if (-not $isAdmin -and -not $developerModeEnabled) {
    throw "Symbolic link creation requires Developer Mode or elevated permissions. Enable Developer Mode or run PowerShell as Administrator."
  }

  Write-VerboseLine "  symlink capability: administrator=$isAdmin developer_mode=$developerModeEnabled"
}

function Assert-WingetPackageIdsExist {
  param(
    [Parameter(Mandatory = $true)][string]$WingetPath,
    [Parameter(Mandatory = $true)][string[]]$PackageIds
  )

  $missingPackageIds = @()
  foreach ($packageId in $PackageIds) {
    $searchOutput = (& $WingetPath "search" "--id" $packageId "-e" "--accept-source-agreements" 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
      throw "winget search failed for '$packageId': $searchOutput"
    }

    if ($searchOutput -match "No package found matching input criteria") {
      $missingPackageIds += $packageId
      continue
    }

    Write-VerboseLine "  package check: found $packageId"
  }

  if ($missingPackageIds.Count -gt 0) {
    throw "The following package IDs were not found in winget sources: $($missingPackageIds -join ', ')"
  }
}

function Assert-ExpectedLink {
  param(
    [Parameter(Mandatory = $true)][string]$LinkPath,
    [Parameter(Mandatory = $true)][string]$ExpectedTarget
  )

  $item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
  if ($null -eq $item) {
    throw "Expected link is missing: $LinkPath"
  }

  if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Expected symbolic link at $LinkPath but found a regular file/directory."
  }

  $currentTarget = $item.Target
  if ($currentTarget -is [array]) {
    $currentTarget = $currentTarget[0]
  }

  if ([string]::IsNullOrWhiteSpace($currentTarget)) {
    throw "Could not resolve symbolic link target for $LinkPath"
  }

  if (-not [IO.Path]::IsPathRooted($currentTarget)) {
    $currentTarget = Join-Path (Split-Path -Parent $LinkPath) $currentTarget
  }

  $normalizedCurrent = Resolve-NormalizedPath -Path $currentTarget
  $normalizedExpected = Resolve-NormalizedPath -Path $ExpectedTarget
  if (-not $normalizedCurrent -or -not $normalizedExpected -or $normalizedCurrent -ne $normalizedExpected) {
    throw "Symbolic link mismatch for $LinkPath. Expected '$ExpectedTarget', found '$currentTarget'."
  }
}

function Link-WithBackup {
  param(
    [Parameter(Mandatory = $true)][string]$LinkTarget,
    [Parameter(Mandatory = $true)][string]$LinkPath
  )

  if (-not (Test-Path -LiteralPath $LinkTarget)) {
    throw "Missing symlink target: $LinkTarget"
  }

  $linkParent = Split-Path -Parent $LinkPath
  if (-not (Test-Path -LiteralPath $linkParent)) {
    Invoke-ManagedCommand `
      -Display "New-Item -ItemType Directory -Path $linkParent -Force" `
      -Command { New-Item -ItemType Directory -Path $linkParent -Force | Out-Null }
  }

  $item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
  if ($null -ne $item) {
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      $currentTarget = $item.Target
      if ($currentTarget -is [array]) {
        $currentTarget = $currentTarget[0]
      }

      if (-not [string]::IsNullOrWhiteSpace($currentTarget)) {
        if (-not [IO.Path]::IsPathRooted($currentTarget)) {
          $currentTarget = Join-Path (Split-Path -Parent $LinkPath) $currentTarget
        }
        $normalizedCurrent = Resolve-NormalizedPath -Path $currentTarget
        $normalizedExpected = Resolve-NormalizedPath -Path $LinkTarget
        if ($normalizedCurrent -and $normalizedExpected -and ($normalizedCurrent -eq $normalizedExpected)) {
          Write-VerboseLine "  link: already correct ($LinkPath -> $LinkTarget)"
          return
        }
      }
    }

    $backupPath = "$LinkPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    if ($DryRun) {
      Write-Info "  link: would back up $LinkPath -> $backupPath"
    } else {
      Move-Item -LiteralPath $LinkPath -Destination $backupPath -Force
      Write-VerboseLine "  link: backed up $LinkPath -> $backupPath"
    }
  }

  if ($DryRun) {
    Write-Info "  link: would create $LinkPath -> $LinkTarget"
    return
  }

  try {
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $LinkTarget -Force | Out-Null
    Write-VerboseLine "  link: created $LinkPath -> $LinkTarget"
  } catch {
    throw "Failed to create symlink at $LinkPath. Enable Developer Mode or run with elevated permissions, then retry."
  }
}

Write-Info "dotfiles bootstrap (Windows)"
Write-Info ""

$isWindowsRuntime = $false
if (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) {
  $isWindowsRuntime = [bool]$IsWindows
} elseif ($env:OS -eq "Windows_NT") {
  $isWindowsRuntime = $true
}

if (-not $isWindowsRuntime) {
  throw "This bootstrap is intended for Windows. Detected: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"
}

if (-not (Test-Path -LiteralPath $ZshrcTarget)) {
  throw "Missing symlink target: $ZshrcTarget"
}

if (-not (Test-Path -LiteralPath $ZprofileTarget)) {
  throw "Missing symlink target: $ZprofileTarget"
}

Step-Start "Run preflight checks"
if (-not (Test-Path -LiteralPath $DotfilesDir)) {
  throw "Dotfiles directory not found at $DotfilesDir"
}
Assert-SymlinkCapability
Step-Ok "environment ready"

$WingetBin = $null

Step-Start "Resolve winget"
$WingetBin = Resolve-WingetBin
if ([string]::IsNullOrWhiteSpace($WingetBin)) {
  $SkipPackages = $true
  Step-Skip "winget not found; package install skipped"
} else {
  Step-Ok $WingetBin
}

Step-Start "Install winget packages"
if ($SkipPackages) {
  Step-Skip "skipped (--skip-packages or winget missing)"
} else {
  if (-not (Test-Path -LiteralPath $WingetManifest)) {
    throw "Winget manifest not found at $WingetManifest"
  }

  $packageIds = Get-WingetPackageIds -ManifestPath $WingetManifest
  if ($packageIds.Count -eq 0) {
    Step-Skip "manifest empty"
  } else {
    Assert-WingetPackageIdsExist -WingetPath $WingetBin -PackageIds $packageIds
    foreach ($packageId in $packageIds) {
      Invoke-ManagedCommand `
        -Display "$WingetBin install --id $packageId -e --silent --accept-package-agreements --accept-source-agreements" `
        -Command { & $WingetBin "install" "--id" $packageId "-e" "--silent" "--accept-package-agreements" "--accept-source-agreements" }
    }
    Step-Ok ("{0} package(s) processed" -f $packageIds.Count)
  }
}

Step-Start "Link shell config files"
Link-WithBackup -LinkTarget $ZshrcTarget -LinkPath (Join-Path $HomePath ".zshrc")
Link-WithBackup -LinkTarget $ZprofileTarget -LinkPath (Join-Path $HomePath ".zprofile")
Step-Ok "linked/verified"

Step-Start "Verify linked files"
if ($DryRun) {
  Step-Skip "skipped in dry-run"
} else {
  Assert-ExpectedLink -LinkPath (Join-Path $HomePath ".zshrc") -ExpectedTarget $ZshrcTarget
  Assert-ExpectedLink -LinkPath (Join-Path $HomePath ".zprofile") -ExpectedTarget $ZprofileTarget
  Step-Ok "links verified"
}

$elapsedSeconds = [int]((Get-Date) - $StartTime).TotalSeconds
Write-Info ""
Write-Info ("Completed in {0}s  |  {1} succeeded  |  {2} skipped" -f $elapsedSeconds, $OkCount, $SkipCount)
Write-Info "Optional local overrides:"
Write-Info "  Copy-Item `"$HOME\.dotfiles\config\zsh\local.example.zsh`" `"$HOME\.dotfiles\config\zsh\local.zsh`""

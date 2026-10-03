#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$wrapper = Join-Path $repoRoot 'install/bootstrap.ps1'
$platformBootstrap = Join-Path $repoRoot 'install/platforms/windows/bootstrap.ps1'
$entrypoints = @($wrapper, $platformBootstrap)

foreach ($path in $entrypoints) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "PowerShell parse errors in $path`: $($errors -join '; ')"
  }
}

$source = Get-Content -LiteralPath $platformBootstrap -Raw
if ($source -notmatch '(?m)^\s*"--link-windows-shell"\s*\{\s*throw') {
  throw 'The retired --link-windows-shell option must remain an explicit error.'
}
if ($source -match 'ln -sfn|Convert-ToWslPath|Link-WithBackup|Assert-ExpectedLink|ZshrcTarget|ZprofileTarget') {
  throw 'Windows bootstrap must not manage native Zsh links.'
}
if ($source -notmatch '-1978335212' -or $source -notmatch '2316632084') {
  throw 'The winget exact-ID not-found result must be handled as a missing package.'
}

$manifestPath = Join-Path $repoRoot 'install/platforms/windows/winget-packages.txt'
$packageIds = @(Get-Content -LiteralPath $manifestPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
foreach ($retiredPackage in @('Microsoft.WSL', 'Git.Git', 'GitHub.cli', 'BurntSushi.ripgrep.MSVC', 'junegunn.fzf', 'OpenJS.NodeJS.LTS', 'Yarn.Yarn')) {
  if ($packageIds -contains $retiredPackage) { throw "Non-host application returned to the Windows manifest: $retiredPackage" }
}

$powerShellPath = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-windows-check-{0}" -f [guid]::NewGuid().ToString('N'))
$oldPath = $env:PATH
$oldMode = $env:DOTFILES_TEST_WINGET_MODE
try {
  New-Item -ItemType Directory -Path $testRoot | Out-Null
  $fakeWinget = @'
@echo off
if /I not "%1"=="list" exit /b 20
if /I "%DOTFILES_TEST_WINGET_MODE%"=="installed" (
  echo Test Application    %3    1.0.0
  exit /b 0
)
if /I "%DOTFILES_TEST_WINGET_MODE%"=="absent" exit /b 0x8A150014
if /I "%DOTFILES_TEST_WINGET_MODE%"=="error" exit /b 9
exit /b 21
'@
  Set-Content -LiteralPath (Join-Path $testRoot 'winget.cmd') -Value $fakeWinget -Encoding Ascii
  $env:PATH = "$testRoot;$oldPath"

  foreach ($mode in @('installed', 'absent')) {
    $env:DOTFILES_TEST_WINGET_MODE = $mode
    $output = (& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $wrapper --dry-run --yes 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
      throw "Windows bootstrap failed for mocked winget '$mode' state: $output"
    }
  }

  $env:DOTFILES_TEST_WINGET_MODE = 'error'
  # Windows PowerShell 5.1 represents redirected native stderr as nonterminating
  # error records. Allow this expected failing probe to return its exit code.
  $savedErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $output = (& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $wrapper --dry-run --yes 2>&1 | Out-String)
    $queryFailureExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
  }
  if ($queryFailureExitCode -eq 0) {
    throw "Windows bootstrap accepted a genuine winget query failure: $output"
  }
} finally {
  $env:PATH = $oldPath
  $env:DOTFILES_TEST_WINGET_MODE = $oldMode
  Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

& $platformBootstrap --dry-run --skip-packages
Write-Host 'Windows PowerShell checks passed.'

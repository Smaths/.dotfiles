# Unified Windows bootstrap entrypoint.
# Dispatches to the platform-specific PowerShell bootstrap.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

& "$PSScriptRoot/platforms/windows/bootstrap.ps1" @args
# Native commands used internally may set LASTEXITCODE even when the platform
# bootstrap handles that state successfully. Reaching here means no terminating
# error escaped.
exit 0

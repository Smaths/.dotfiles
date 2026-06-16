# Unified Windows bootstrap entrypoint.
# Dispatches to the platform-specific PowerShell bootstrap.

& "$PSScriptRoot/platforms/windows/bootstrap.ps1" @args
exit $LASTEXITCODE

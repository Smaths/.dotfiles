# Unified Windows bootstrap entrypoint.
# Dispatches to the platform-specific PowerShell bootstrap.

& "$PSScriptRoot/platforms/bootstrap-windows.ps1" @args
exit $LASTEXITCODE

# Unified Windows bootstrap entrypoint.
# Dispatches to the platform-specific PowerShell bootstrap.

& "$PSScriptRoot/bootstrap-windows.ps1" @args
exit $LASTEXITCODE

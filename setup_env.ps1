param(
    [string]$VenvDir = "$env:USERPROFILE\.venvs\moneyPrinterTurbo",
    [string]$ConfigDir = $(if ($env:MPT_CONFIG_DIR) { $env:MPT_CONFIG_DIR } else { Join-Path $env:LOCALAPPDATA "moneyPrinterTurbo" })
)

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonExe = "py"
    $PythonArgs = @("-3.11")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonExe = "python"
    $PythonArgs = @()
} else {
    throw "Python was not found. Install Python 3.11 first, then rerun this script."
}

$Version = & $PythonExe @PythonArgs -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
if ($Version -notin @("3.11", "3.12")) {
    throw "MoneyPrinterTurbo requires Python >=3.11,<3.13. Found $Version."
}

New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

$LocalConfig = Join-Path $ConfigDir "config.toml"
$LegacyConfig = Join-Path $ProjectDir "config.toml"
$ExampleConfig = Join-Path $ProjectDir "config.example.toml"
if ((Test-Path $LegacyConfig) -and -not (Test-Path $LocalConfig)) {
    Copy-Item $LegacyConfig $LocalConfig
    Write-Host "Migrated local config to: $LocalConfig"
} elseif (-not (Test-Path $LocalConfig)) {
    Copy-Item $ExampleConfig $LocalConfig
    Write-Host "Created local config template: $LocalConfig"
    Write-Host "Fill in local config values before running the app."
}

& $PythonExe @PythonArgs -m venv $VenvDir
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip install -r (Join-Path $ProjectDir "requirements.txt")
& $VenvPython -B -m py_compile (Join-Path $ProjectDir "main.py") (Join-Path $ProjectDir "app\config\config.py")

Write-Host "Ready. Virtualenv is outside OneDrive: $VenvDir"
Write-Host "Local config is outside OneDrive: $LocalConfig"
Write-Host "Use it on Windows PowerShell with: & `"$VenvDir\Scripts\Activate.ps1`""
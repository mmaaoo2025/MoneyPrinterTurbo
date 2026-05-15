param(
    [string]$VenvDir = "$env:USERPROFILE\.venvs\moneyPrinterTurbo",
    [string]$ConfigDir = $(if ($env:MPT_CONFIG_DIR) { $env:MPT_CONFIG_DIR } else { Join-Path $env:LOCALAPPDATA "moneyPrinterTurbo" })
)

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Probe candidate launchers in priority order and pick the first one that
# actually reports a supported version (>=3.11, <3.13). This keeps the error
# message clear when `py` exists but a usable interpreter is not installed.
$Candidates = @()
if (Get-Command py -ErrorAction SilentlyContinue) {
    $Candidates += , @{ Exe = "py"; Args = @("-3.11") }
    $Candidates += , @{ Exe = "py"; Args = @("-3.12") }
}
if (Get-Command python -ErrorAction SilentlyContinue) {
    $Candidates += , @{ Exe = "python"; Args = @() }
}

$PythonExe = $null
$PythonArgs = $null
$Version = $null
$Tried = @()
foreach ($cand in $Candidates) {
    $label = ($cand.Exe + " " + ($cand.Args -join " ")).Trim()
    $Tried += $label
    try {
        $v = & $cand.Exe @($cand.Args) -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
    } catch {
        continue
    }
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($v)) { continue }
    if ($v -in @("3.11", "3.12")) {
        $PythonExe = $cand.Exe
        $PythonArgs = $cand.Args
        $Version = $v
        break
    }
}

if (-not $PythonExe) {
    $msg = "MoneyPrinterTurbo requires Python >=3.11,<3.13, but no matching interpreter was found.`n"
    if ($Tried.Count -gt 0) { $msg += "Tried: " + ($Tried -join ", ") + "`n" }
    $msg += "Install Python 3.11 (e.g. `winget install Python.Python.3.11`), then rerun this script."
    throw $msg
}

Write-Host "Using Python $Version via: $PythonExe $($PythonArgs -join ' ')"

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
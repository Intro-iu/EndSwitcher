param (
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

if (-not $SkipBuild) {
    Write-Host "=> Building Flutter Windows Application (Release Mode)..." -ForegroundColor Cyan
    # Ensure rust and dart bindings are up to date
    flutter_rust_bridge_codegen generate
    # Build windows executable
    flutter build windows --release
}

$flutterOut = "build\windows\x64\runner\Release"
if (-not (Test-Path $flutterOut)) {
    Write-Host "[ERROR] Build directory $flutterOut not found! Did flutter build succeed?" -ForegroundColor Red
    exit 1
}

$packerName = "warp-packer.exe"
if (-not (Test-Path $packerName)) {
    Write-Host "=> Downloading warp-packer (Single File Executable Packager)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/dgiagio/warp/releases/download/v0.3.0/windows-x64.warp-packer.exe" -OutFile $packerName
}

Write-Host "=> Assembling single executable..." -ForegroundColor Cyan
# Run warp-packer to encapsulate the entire Release folder and specify the entrypoint executable
& .\$packerName --arch windows-x64 --input_dir $flutterOut --exec endswitcher.exe --output EndSwitcher_Standalone.exe

# Patch PE subsystem to Windows GUI (2) instead of Console (3) to prevent terminal popup
Write-Host "=> Patching PE subsystem to GUI (hiding console window)..." -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes('EndSwitcher_Standalone.exe')
$elfanew = [BitConverter]::ToInt32($bytes, 0x3C)
$subsystemOffset = $elfanew + 24 + 68
$bytes[$subsystemOffset] = 2 # IMAGE_SUBSYSTEM_WINDOWS_GUI
[System.IO.File]::WriteAllBytes("$PWD\EndSwitcher_Standalone.exe", $bytes)

Write-Host "=> [Done] Saved standalone executable as 'EndSwitcher_Standalone.exe'!" -ForegroundColor Green

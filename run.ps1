#!/usr/bin/env pwsh
# run.ps1 — restart the installed midnight-miner whenever it exits

param(
    [Parameter(Mandatory=$false)]
    [int]$Delay = 2,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ProgArgs
)

$ErrorActionPreference = "Continue"  # Don't stop the loop on errors

# Use same defaults as install.ps1
$IsWindowsOS = $IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6)
$defaultBinDir = if ($IsWindowsOS) {
    "$env:USERPROFILE\AppData\Local\Programs"
} else {
    "$env:HOME/.local/bin"
}

$BinDir = if ($env:BIN_DIR) { $env:BIN_DIR } else { $defaultBinDir }
$Name = if ($env:NAME) { $env:NAME } else { "midnight-miner" }

# Add .exe extension on Windows if not present
if ($IsWindowsOS -and $Name -notlike "*.exe") {
    $Name += ".exe"
}

# Prefer local binary in current directory, otherwise use BinDir
$localMiner = Join-Path "." $Name
if (Test-Path $localMiner) {
    $Miner = $localMiner
    Write-Host "[run_loop] using local binary: $Miner"
} else {
    $Miner = Join-Path $BinDir $Name
}

# Check if binary exists
if (-not (Test-Path $Miner)) {
    Write-Host "error: $Miner not found" -ForegroundColor Red
    Write-Host "       run install.ps1 first"
    exit 1
}

# Stop cleanly on Ctrl+C
$script:shouldExit = $false
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host ""
    Write-Host "[run_loop] stopping..."
}

[Console]::TreatControlCAsInput = $false
$cancelHandler = {
    $script:shouldExit = $true
}
$null = Register-ObjectEvent -InputObject ([Console]) -EventName CancelKeyPress -Action $cancelHandler

$Launches = 0
$BaseDelay = $Delay

Write-Host "[run_loop] starting (Ctrl+C to stop)..."

while (-not $script:shouldExit) {
    $Launches++
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[run_loop] $timestamp - launch #$Launches"
    $startTime = Get-Date
    
    # Run the miner
    if ($ProgArgs) {
        & $Miner @ProgArgs
    } else {
        & $Miner
    }
    $exitCode = $LASTEXITCODE
    
    $endTime = Get-Date
    $duration = [int](($endTime - $startTime).TotalSeconds)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[run_loop] $timestamp - exited with code $exitCode after ${duration}s"
    
    # Check if we should exit
    if ($script:shouldExit) {
        break
    }
    
    # Exponential backoff if it exits instantly (<1s)
    if ($duration -lt 1) {
        $Delay = $Delay * 2
        if ($Delay -gt 30) {
            $Delay = 30
        }
    } else {
        $Delay = $BaseDelay
    }
    
    Write-Host "[run_loop] restarting in ${Delay}s (Ctrl+C to stop)..."
    
    # Sleep with interrupt check
    $sleepEnd = (Get-Date).AddSeconds($Delay)
    while ((Get-Date) -lt $sleepEnd -and -not $script:shouldExit) {
        Start-Sleep -Milliseconds 100
    }
}

Write-Host "[run_loop] stopped."


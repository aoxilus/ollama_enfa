#!/usr/bin/env pwsh
param(
    [string]$Endpoint = "http://127.0.0.1:8080",
    [string]$Model = "local",
    [switch]$SkipPing,
    [int]$PingTimeoutSec = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path $PSScriptRoot).Path
$runner = Join-Path $repo "test\run_3_programs_and_evaluate.ps1"
$pinger = Join-Path $repo "test\ping_model.ps1"

if (-not (Test-Path -LiteralPath $runner)) {
    Write-Host "Missing runner: $runner" -ForegroundColor Red
    exit 1
}

if (-not $SkipPing) {
    if (-not (Test-Path -LiteralPath $pinger)) {
        Write-Host "Missing ping script: $pinger" -ForegroundColor Red
        exit 1
    }
    & $pinger -Endpoint $Endpoint -Model $Model -TimeoutSec $PingTimeoutSec
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Quick ping failed; use -SkipPing to run full eval only." -ForegroundColor Yellow
        exit 1
    }
}

& $runner -Endpoint $Endpoint -Model $Model
exit $LASTEXITCODE

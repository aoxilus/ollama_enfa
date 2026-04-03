#!/usr/bin/env pwsh
param(
    [string]$Endpoint = "http://127.0.0.1:8080",
    [string]$Model = "local",
    [int]$TimeoutSec = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$base = $Endpoint.TrimEnd("/")
$body = @{
    model      = $Model
    messages   = @(@{ role = "user"; content = "What is 2+2? Answer with only the number." })
    temperature = 0
    max_tokens = 10
    stream     = $false
}

try {
    $r = Invoke-RestMethod -Uri "$base/v1/chat/completions" -Method Post `
        -Body ($body | ConvertTo-Json -Depth 8) -ContentType "application/json" -TimeoutSec $TimeoutSec
    if (-not $r -or -not $r.choices -or $r.choices.Count -lt 1) {
        Write-Host "PING_FAIL: no choices" -ForegroundColor Red
        exit 1
    }
    $txt = [string]$r.choices[0].message.content
    Write-Output "MODEL_REPLY: $txt"
    if ($txt -match "4") {
        Write-Output "PING_OK"
        exit 0
    }
    Write-Host "PING_FAIL: unexpected reply" -ForegroundColor Red
    exit 1
} catch {
    Write-Host "PING_FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

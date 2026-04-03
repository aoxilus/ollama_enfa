#!/usr/bin/env pwsh
# Pester 5+ unit tests (no llama-server required; uses stub client).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]"5.0.0" })) {
    Install-Module -Name Pester -Force -MinimumVersion 5.6.0 -Scope CurrentUser -AllowClobber -ErrorAction Stop
}

Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

$ws = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }
$unit = Join-Path $ws "test\unit"

$config = New-PesterConfiguration
$config.Run.Path = $unit
$config.Run.PassThru = $true
$config.Output.Verbosity = "Detailed"

if ($env:CI -eq "true" -or $env:GITHUB_ACTIONS -eq "true") {
    $outXml = Join-Path $ws "test-results.xml"
    $outDir = Split-Path -Parent $outXml
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $outXml
    $config.TestResult.OutputFormat = "NUnitXml"
}

$r = Invoke-Pester -Configuration $config
if ($r.FailedCount -gt 0) {
    exit 1
}
Write-Host "UNIT_OK failed=$($r.FailedCount) passed=$($r.PassedCount)"
exit 0

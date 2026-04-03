#!/usr/bin/env pwsh
# Parse PowerShell scripts on the Butler-critical path (matches repo contract).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ws = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }

$explicit = @(
    (Join-Path $ws "verify.ps1"),
    (Join-Path $ws "powershell\butler_profile.ps1"),
    (Join-Path $ws "powershell\ButlerCppBridge.ps1"),
    (Join-Path $ws "powershell\setup_butler.ps1"),
    (Join-Path $ws "powershell\install_profile.ps1"),
    (Join-Path $ws "powershell\uninstall_profile.ps1"),
    (Join-Path $ws "scripts\ci_parse_pwsh.ps1"),
    (Join-Path $ws "scripts\run_unit_tests.ps1")
)

$files = [System.Collections.Generic.List[string]]::new()
foreach ($p in $explicit) {
    if (Test-Path -LiteralPath $p) { $files.Add($p) }
}

$testDir = Join-Path $ws "test"
if (Test-Path -LiteralPath $testDir) {
    Get-ChildItem -LiteralPath $testDir -Recurse -Filter *.ps1 -File |
        Where-Object { $_.FullName -notmatch '[\\/]legacy[\\/]' } |
        ForEach-Object { $files.Add($_.FullName) }
}

$failed = $false
foreach ($f in $files) {
    $errs = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)
    if ($errs.Count -gt 0) {
        $failed = $true
        Write-Host "PARSE_FAIL $f"
        foreach ($e in $errs) { Write-Host $e }
    }
}
if ($failed) { exit 1 }
Write-Host "OK: $($files.Count) scripts"

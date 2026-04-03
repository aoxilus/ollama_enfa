#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Cursor Butler setup: llama.cpp server + GGUF model + smoke test
.PARAMETER BaseDir
  Where to install binaries/models (default: repo/.butler)
.PARAMETER Port
  Server port (default: 8080)
.PARAMETER Host
  Server host (default: 127.0.0.1)
.PARAMETER ModelUrl
  Direct download URL for GGUF model
.PARAMETER ModelFile
  Output filename for GGUF model
.PARAMETER UninstallOllama
  Attempt to uninstall Ollama via winget
.PARAMETER Yes
  Auto-approve uninstall/download/start/test prompts
#>

param(
    [string]$BaseDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".butler"),
    [string]$BindHost = "127.0.0.1",
    [int]$Port = 8080,
    [string]$ModelUrl = "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf?download=true",
    [string]$ModelFile = "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
    [switch]$UninstallOllama,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Confirm-Step {
    param([string]$Message)
    if ($Yes) { return $true }
    $a = Read-Host "$Message (y/n)"
    return ($a -eq "y" -or $a -eq "Y" -or $a -eq "s" -or $a -eq "S")
}

function Get-LlamaCppRelease {
    $u = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
    $r = Invoke-RestMethod -Uri $u -Method Get -Headers @{ "User-Agent" = "CursorButlerSetup" }
    if (-not $r -or -not $r.assets) { throw "Could not query llama.cpp releases" }

    $asset = $r.assets | Where-Object { $_.name -like "*bin-win-cpu-x64.zip" } | Select-Object -First 1
    if (-not $asset) {
        $asset = $r.assets | Where-Object { $_.name -like "*win*cpu*x64*.zip" } | Select-Object -First 1
    }
    if (-not $asset -or -not $asset.browser_download_url) {
        throw "No Windows x64 CPU asset found in latest llama.cpp release"
    }

    return @{
        Tag = $r.tag_name
        Name = $asset.name
        Url = $asset.browser_download_url
    }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Download-File {
    param([string]$Url, [string]$OutFile)
    if (Test-Path $OutFile) { return }
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Try-UninstallOllama {
    if (-not $UninstallOllama) { return }
    if (-not (Confirm-Step "Uninstall Ollama via winget?")) { return }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Host "winget not found. Skipping uninstall." -ForegroundColor Yellow
        return
    }

    try {
        & winget uninstall --id Ollama.Ollama -e
    } catch {
        Write-Host "Ollama uninstall failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Start-ButlerServer {
    param(
        [string]$ServerExe,
        [string]$ModelPath,
        [string]$BindHost,
        [int]$BindPort
    )

    $arg = "--host $BindHost --port $BindPort --model `"$ModelPath`" --ctx-size 4096"

    $logDir = Join-Path (Split-Path $ServerExe -Parent) "..\\logs"
    Ensure-Dir $logDir
    $outLog = Join-Path $logDir "llama-server.out.txt"
    $errLog = Join-Path $logDir "llama-server.err.txt"

    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }

    $p = Start-Process -FilePath $ServerExe -ArgumentList $arg -PassThru -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    return $p
}

function Wait-ServerReady {
    param([string]$Endpoint, [System.Diagnostics.Process]$Process)

    $ready = $false
    for ($i = 0; $i -lt 600; $i++) {
        if ($Process -and $Process.HasExited) {
            throw "Server exited while starting"
        }
        try {
            $null = Invoke-RestMethod -Uri "$Endpoint/v1/models" -Method Get -TimeoutSec 10
            $ready = $true
            break
        } catch {
            Start-Sleep -Milliseconds 1000
        }
    }
    if (-not $ready) { throw "Server not ready at $Endpoint" }
}

function Smoke-Test {
    param([string]$Endpoint)

    $body = @{
        model = "local"
        messages = @(
            @{ role = "user"; content = "What is 2+2? Answer with just the number." }
        )
        temperature = 0.0
        max_tokens = 10
        stream = $false
    }

    $r = Invoke-RestMethod -Uri "$Endpoint/v1/chat/completions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 60
    $t = $null
    if ($r -and $r.choices -and $r.choices.Count -gt 0) {
        $t = [string]$r.choices[0].message.content
    }
    if ([string]::IsNullOrWhiteSpace($t)) { throw "Smoke test: empty response" }
    if ($t -notmatch "4") { throw "Smoke test failed. Response: $t" }
    Write-Host "Smoke test OK: $($t.Trim())" -ForegroundColor Green
}

Ensure-Dir $BaseDir
$binDir = Join-Path $BaseDir "bin"
$modelDir = Join-Path $BaseDir "models"
Ensure-Dir $binDir
Ensure-Dir $modelDir

Try-UninstallOllama

if (-not (Confirm-Step "Download llama.cpp (llama-server) and GGUF model?")) {
    throw "Cancelled"
}

$rel = Get-LlamaCppRelease
$zipPath = Join-Path $binDir $rel.Name
Write-Host "Downloading llama.cpp: $($rel.Tag)" -ForegroundColor Cyan
Download-File -Url $rel.Url -OutFile $zipPath

Expand-Archive -Path $zipPath -DestinationPath $binDir -Force

$serverExe = Get-ChildItem -Path $binDir -Recurse -Filter "llama-server.exe" | Select-Object -First 1
if (-not $serverExe) { throw "llama-server.exe not found after extract" }

$modelPath = Join-Path $modelDir $ModelFile
Write-Host "Downloading model: $ModelFile" -ForegroundColor Cyan
Download-File -Url $ModelUrl -OutFile $modelPath

$endpoint = "http://$BindHost`:$Port"
$env:BUTLER_ENDPOINT = $endpoint
$env:BUTLER_MODEL = "local"

if (-not (Confirm-Step "Start server and run smoke test?")) {
    Write-Host "Setup completed (downloads done). Start server manually:" -ForegroundColor Yellow
    Write-Host "  `"$($serverExe.FullName)`" --host $BindHost --port $Port --model `"$modelPath`"" -ForegroundColor White
    exit 0
}

$proc = $null
try {
    Write-Host "Starting server on $endpoint" -ForegroundColor Cyan
    $proc = Start-ButlerServer -ServerExe $serverExe.FullName -ModelPath $modelPath -BindHost $BindHost -BindPort $Port
    Write-Host "Waiting for server..." -ForegroundColor Cyan
    Wait-ServerReady -Endpoint $endpoint -Process $proc
    Smoke-Test -Endpoint $endpoint
} finally {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Cursor Butler ready. Endpoint: $endpoint" -ForegroundColor Cyan


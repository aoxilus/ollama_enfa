#!/usr/bin/env pwsh
# Aoxilus Butler PowerShell Integration Profile
# Local AI via llama.cpp server (OpenAI-compatible API)
# Timers: si se cuelga ya bye. See https://learn.microsoft.com/en-us/windows/ai/overview
# When cpp/ollama_client.exe exists (or BUTLER_CPP_CLIENT), chat runs in C++ (ButlerCppBridge.ps1).

$brid = Join-Path $PSScriptRoot "ButlerCppBridge.ps1"
if (Test-Path -LiteralPath $brid) {
    . $brid
}

if ([string]::IsNullOrWhiteSpace($env:BUTLER_ENDPOINT)) {
    $env:BUTLER_ENDPOINT = "http://127.0.0.1:8080"
}
if ([string]::IsNullOrWhiteSpace($env:BUTLER_MODEL)) {
    $env:BUTLER_MODEL = "local"
}
if ([string]::IsNullOrWhiteSpace($env:BUTLER_TIMEOUT_SEC)) {
    $env:BUTLER_TIMEOUT_SEC = "30"
}

$script:ButlerCache = @{}
$script:CacheExpiry = 3600
$script:CacheMaxEntries = 1000
if ($env:BUTLER_CACHE_MAX_ENTRIES) {
    $m = [int]$env:BUTLER_CACHE_MAX_ENTRIES
    if ($m -gt 0) { $script:CacheMaxEntries = $m }
}

function Get-ButlerPromptHash {
    param([string]$Prompt, [string]$Model)
    $content = "$Prompt|$Model"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash($bytes)
        return [System.Convert]::ToBase64String($hash)
    } finally {
        if ($null -ne $sha256) { $sha256.Dispose() }
    }
}

function Get-ButlerCachedResponse {
    param([string]$Prompt, [string]$Model)
    $hash = Get-ButlerPromptHash -Prompt $Prompt -Model $Model
    if ($script:ButlerCache.ContainsKey($hash)) {
        $cached = $script:ButlerCache[$hash]
        if ((Get-Date) -lt $cached.Expiry) {
            $cached.LastAccess = Get-Date
            $script:ButlerCache[$hash] = $cached
            return $cached.Response
        }
        $script:ButlerCache.Remove($hash)
    }
    return $null
}

function Set-ButlerCachedResponse {
    param([string]$Prompt, [string]$Model, [string]$ResponseText)
    $hash = Get-ButlerPromptHash -Prompt $Prompt -Model $Model
    $script:ButlerCache[$hash] = @{
        Response = $ResponseText
        Expiry = (Get-Date).AddSeconds($script:CacheExpiry)
        LastAccess = Get-Date
    }

    # LRU-ish eviction (por LastAccess) para evitar crecimiento infinito.
    $max = $script:CacheMaxEntries
    if ($script:ButlerCache.Count -gt $max) {
        $leastKey = $null
        $leastAccess = $null

        foreach ($k in @($script:ButlerCache.Keys)) {
            $entry = $script:ButlerCache[$k]
            if ($null -eq $leastAccess -or $entry.LastAccess -lt $leastAccess) {
                $leastAccess = $entry.LastAccess
                $leastKey = $k
            }
        }

        if ($leastKey) { $script:ButlerCache.Remove($leastKey) | Out-Null }
    }
}

function Invoke-ButlerChat {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [Parameter(Mandatory=$false)]
        [int]$MaxTokens = 128,
        [Parameter(Mandatory=$false)]
        [double]$Temperature = 0.7,
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSec = 0,
        [Parameter(Mandatory=$false)]
        [string]$SystemPrompt = "You are Aoxilus Butler. Answer concisely. If code is requested, output only working code.",
        [switch]$ChatFast
    )
    if ($TimeoutSec -le 0) {
        $TimeoutSec = [int]$env:BUTLER_TIMEOUT_SEC
        if ($TimeoutSec -le 0) { $TimeoutSec = 30 }
    }

    if (Get-Command Get-ButlerCppExecutable -ErrorAction SilentlyContinue) {
        $cpp = Get-ButlerCppExecutable
        if ($cpp) {
            return Invoke-ButlerCppInvoke -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -TimeoutSec $TimeoutSec -SystemPrompt $SystemPrompt -ChatFast:$ChatFast
        }
    }

    $endpoint = $env:BUTLER_ENDPOINT.TrimEnd("/")
    $url = "$endpoint/v1/chat/completions"

    $body = @{
        model = $env:BUTLER_MODEL
        messages = @(
            @{ role = "system"; content = $SystemPrompt }
            @{ role = "user"; content = $Prompt }
        )
        temperature = $Temperature
        max_tokens = $MaxTokens
        stream = $false
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Uri $url -Method Post -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $TimeoutSec
    $sw.Stop()

    $text = $null
    if ($resp -and $resp.choices -and $resp.choices.Count -gt 0) {
        $choice = $resp.choices[0]
        if ($choice.message -and $choice.message.content) {
            $text = [string]$choice.message.content
        }
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "No content in response"
    }

    return @{
        Text = $text.Trim()
        Ms = $sw.ElapsedMilliseconds
        Raw = $resp
    }
}

function Ask-Butler {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Question,
        [switch]$NoCache
    )

    if (-not $NoCache) {
        $cached = Get-ButlerCachedResponse -Prompt $Question -Model $env:BUTLER_MODEL
        if ($cached) {
            Write-Host $cached -ForegroundColor White
            return
        }
    }

    try {
        $r = Invoke-ButlerChat -Prompt $Question -MaxTokens 200 -Temperature 0.7 -TimeoutSec ([int]$env:BUTLER_TIMEOUT_SEC)
        if (-not $NoCache) {
            Set-ButlerCachedResponse -Prompt $Question -Model $env:BUTLER_MODEL -ResponseText $r.Text
        }
        Write-Host $r.Text -ForegroundColor White
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Ask-ButlerFast {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Question,
        [switch]$NoCache
    )
    $p = "$Question`nAnswer in one short sentence."
    try {
        $r = Invoke-ButlerChat -Prompt $p -MaxTokens 40 -Temperature 0.1 -TimeoutSec ([int]$env:BUTLER_TIMEOUT_SEC) -ChatFast
        if (-not $NoCache) {
            Set-ButlerCachedResponse -Prompt $p -Model $env:BUTLER_MODEL -ResponseText $r.Text
        }
        Write-Host $r.Text -ForegroundColor White
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Generate-Code {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Request,
        [switch]$NoCache
    )
    $p = "Write working code only. No explanations.`nTask: $Request"
    if (-not $NoCache) {
        $cached = Get-ButlerCachedResponse -Prompt $p -Model $env:BUTLER_MODEL
        if ($cached) {
            Write-Host $cached -ForegroundColor White
            return
        }
    }
    try {
        $r = Invoke-ButlerChat -Prompt $p -MaxTokens 600 -Temperature 0.2 -TimeoutSec 120 -SystemPrompt "You are Aoxilus Butler. Output only working code. No markdown fences. No explanation."
        if (-not $NoCache) {
            Set-ButlerCachedResponse -Prompt $p -Model $env:BUTLER_MODEL -ResponseText $r.Text
        }
        Write-Host $r.Text -ForegroundColor White
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Analyze-File {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-Host "Error: file not found: $Path" -ForegroundColor Red
        return
    }
    $text = ""
    try {
        $text = Get-Content -Path $Path -Raw -Encoding UTF8
    } catch {
        $text = Get-Content -Path $Path -Raw
    }
    if ($text.Length -gt 12000) {
        $text = $text.Substring(0, 12000)
    }
    $p = "Analyze this file and give concise actionable feedback.`nFILE: $Path`nCONTENT:`n$text"
    try {
        $r = Invoke-ButlerChat -Prompt $p -MaxTokens 300 -Temperature 0.2 -TimeoutSec 120 -SystemPrompt "You are Aoxilus Butler. Give concise actionable feedback on the file."
        Write-Host $r.Text -ForegroundColor White
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-ButlerModel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Model
    )
    $env:BUTLER_MODEL = $Model
}

function Get-ButlerStatus {
    $endpoint = $env:BUTLER_ENDPOINT.TrimEnd("/")
    Write-Host "Aoxilus Butler:" -ForegroundColor Cyan
    Write-Host "  Endpoint: $endpoint" -ForegroundColor White
    Write-Host "  Model: $env:BUTLER_MODEL" -ForegroundColor White
    Write-Host "  Cache: $($script:ButlerCache.Count) entries" -ForegroundColor White
    if (Get-Command Get-ButlerCppExecutable -ErrorAction SilentlyContinue) {
        $ex = Get-ButlerCppExecutable
        if ($ex) {
            Write-Host "  C++ client: $ex" -ForegroundColor Green
        } else {
            Write-Host "  C++ client: (not found; HTTP fallback in profile)" -ForegroundColor Yellow
        }
    }
}

function Clear-ButlerCache {
    $script:ButlerCache.Clear()
}

Set-Alias -Name "ask" -Value Ask-Butler
Set-Alias -Name "fast" -Value Ask-ButlerFast
Set-Alias -Name "code" -Value Generate-Code
Set-Alias -Name "analyze" -Value Analyze-File
Set-Alias -Name "model" -Value Set-ButlerModel
Set-Alias -Name "status" -Value Get-ButlerStatus
Set-Alias -Name "clearcache" -Value Clear-ButlerCache


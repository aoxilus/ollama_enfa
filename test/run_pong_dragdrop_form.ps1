#!/usr/bin/env pwsh
# Timers: si se cuelga ya bye. See https://learn.microsoft.com/en-us/windows/ai/overview
param(
    [string]$Endpoint = "http://127.0.0.1:8080",
    [string]$Model = "local",
    [int]$RequestTimeoutSec = 120,
    [int]$ScriptTimeoutSec = 600
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ByeAt = [DateTime]::UtcNow.AddSeconds($ScriptTimeoutSec)
function Assert-NotTimedOut {
    if ([DateTime]::UtcNow -gt $script:ByeAt) { throw "Timed out (bye)" }
}

$scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
$scriptDir = Split-Path -Parent $scriptPath
$repo = (Resolve-Path (Join-Path $scriptDir "..")).Path
Set-Location $repo

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Wait-ServerReady {
    param([string]$BaseUrl)
    for ($i = 0; $i -lt 60; $i++) {
        Assert-NotTimedOut
        try {
            $null = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Method Get -TimeoutSec 5
            return
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    throw "Butler server not ready at $BaseUrl"
}

function Start-LocalServerIfAvailable {
    param([string]$BaseUrl)
    try {
        $null = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Method Get -TimeoutSec 2
        return $null
    } catch { }

    $exe = Resolve-Path ".butler/bin/llama-server.exe" -ErrorAction SilentlyContinue
    if (-not $exe) { return $null }
    $model = Get-ChildItem ".butler/models" -Filter "*.gguf" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $model) { return $null }

    $u = [System.Uri]$BaseUrl
    $bindHost = $u.Host
    $port = if ($u.Port -gt 0) { $u.Port } else { 8080 }
    $logDir = ".butler/logs"
    Ensure-Dir $logDir
    $outLog = Join-Path $logDir "test-ui.out.txt"
    $errLog = Join-Path $logDir "test-ui.err.txt"
    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }

    $argList = @("--host", $bindHost, "--port", $port, "--model", $model.FullName, "--ctx-size", "4096")
    $p = Start-Process -FilePath $exe.Path -ArgumentList $argList -PassThru -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    try {
        Wait-ServerReady -BaseUrl $BaseUrl
        return $p
    } catch {
        if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        throw
    }
}

function Invoke-ButlerChat {
    param(
        [string]$BaseUrl,
        [string]$ModelName,
        [string]$Prompt,
        [int]$MaxTokens = 4000,
        [double]$Temperature = 0.2
    )
    $body = @{
        model = $ModelName
        messages = @(
            @{ role = "system"; content = "Output ONLY the complete HTML file. No markdown fences. No explanations. No extra text before or after the HTML." }
            @{ role = "user"; content = $Prompt }
        )
        temperature = $Temperature
        max_tokens = $MaxTokens
        stream = $false
    }
    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/chat/completions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $RequestTimeoutSec
    if (-not $r -or -not $r.choices -or $r.choices.Count -lt 1) { throw "No choices returned" }
    $t = [string]$r.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($t)) { throw "Empty content" }
    return $t.Trim()
}

function Normalize-HtmlContent {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $t = $Text.Trim()
    if ($t -match '```') {
        $m = [Regex]::Match($t, '```(?:html)?\s*([\s\S]*?)\s*```', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($m.Success) {
            return $m.Groups[1].Value.Trim()
        }
    }
    return $t
}

function Test-PongStructure {
    param([string]$Html)
    $ok = $Html -match '<canvas'
    if (-not $ok) { return $false }
    $ok = ($Html -match 'requestAnimationFrame|setInterval') -or ($Html -match 'addEventListener\s*\(\s*[\''"]keydown|keydown\s*:')
    return $ok
}

function Test-DragDropStructure {
    param([string]$Html)
    $draggable = $Html -match 'draggable\s*=\s*[\''"]true[\''"]|ondragstart|draggable\s*=\s*true'
    $drop = $Html -match 'ondrop|addEventListener\s*\(\s*[\''"]drop[\''"]'
    return ($draggable -and $drop)
}

function Test-FormStructure {
    param([string]$Html)
    $form = $Html -match '<form'
    $inputs = ([Regex]::Matches($Html, '<(?:input|select|textarea)\s')).Count -ge 2
    return ($form -and $inputs)
}

$testDir = Join-Path $repo "test"
$genDir = Join-Path $testDir "generated"
Ensure-Dir $genDir

$serverProc = $null
try {
    $serverProc = Start-LocalServerIfAvailable -BaseUrl $Endpoint

    Assert-NotTimedOut
    $pongPrompt = @"
Create a single HTML file that implements a playable Pong game.
- Use one <canvas> for drawing.
- Player controls a paddle (e.g. arrow keys or mouse).
- Ball bounces off walls and paddle; score or simple game loop.
- One file only, no external scripts. Inline JavaScript is fine.
"@

    $dragPrompt = @"
Create a single HTML file that demonstrates drag and drop.
- At least one element is draggable (draggable=true or ondragstart).
- A drop zone that accepts the dragged item (ondrop or drop listener).
- Show visually that the item was dropped (e.g. move element or display text).
- One file only, inline CSS/JS.
"@

    $formPrompt = @"
Create a single HTML file with a form.
- A <form> containing at least two fields (e.g. input text, email, select, or textarea).
- A submit button.
- Optional: simple inline validation or display of values.
- One file only, inline CSS/JS if needed.
"@

    $s1 = Invoke-ButlerChat -BaseUrl $Endpoint -ModelName $Model -Prompt $pongPrompt -MaxTokens 3500 -Temperature 0.2
    $s1 = Normalize-HtmlContent -Text $s1
    $f1 = Join-Path $genDir "pong.html"
    [System.IO.File]::WriteAllText($f1, $s1, [System.Text.Encoding]::UTF8)

    Assert-NotTimedOut
    $s2 = Invoke-ButlerChat -BaseUrl $Endpoint -ModelName $Model -Prompt $dragPrompt -MaxTokens 3500 -Temperature 0.2
    $s2 = Normalize-HtmlContent -Text $s2
    $f2 = Join-Path $genDir "dragdrop.html"
    [System.IO.File]::WriteAllText($f2, $s2, [System.Text.Encoding]::UTF8)

    Assert-NotTimedOut
    $s3 = Invoke-ButlerChat -BaseUrl $Endpoint -ModelName $Model -Prompt $formPrompt -MaxTokens 3500 -Temperature 0.2
    $s3 = Normalize-HtmlContent -Text $s3
    $f3 = Join-Path $genDir "form.html"
    [System.IO.File]::WriteAllText($f3, $s3, [System.Text.Encoding]::UTF8)

    $html1 = [System.IO.File]::ReadAllText($f1, [System.Text.Encoding]::UTF8)
    $html2 = [System.IO.File]::ReadAllText($f2, [System.Text.Encoding]::UTF8)
    $html3 = [System.IO.File]::ReadAllText($f3, [System.Text.Encoding]::UTF8)

    $ok1 = Test-PongStructure -Html $html1
    $ok2 = Test-DragDropStructure -Html $html2
    $ok3 = Test-FormStructure -Html $html3

    if ($ok1) { "pong PASS" } else { "pong FAIL (missing canvas or game loop)" }
    if ($ok2) { "dragdrop PASS" } else { "dragdrop FAIL (missing draggable/drop)" }
    if ($ok3) { "form PASS" } else { "form FAIL (missing form or 2+ inputs)" }

    if (-not ($ok1 -and $ok2 -and $ok3)) { exit 2 }
} finally {
    if ($serverProc -and -not $serverProc.HasExited) {
        Stop-Process -Id $serverProc.Id -Force -ErrorAction SilentlyContinue
    }
}

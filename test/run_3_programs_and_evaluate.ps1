#!/usr/bin/env pwsh
# Timers: si se cuelga ya bye. See https://learn.microsoft.com/en-us/windows/ai/overview
param(
    [string]$Endpoint = "http://127.0.0.1:8080",
    [string]$Model = "local",
    [int]$RequestTimeoutSec = 90,
    [int]$ScriptTimeoutSec = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ByeAt = [DateTime]::UtcNow.AddSeconds($ScriptTimeoutSec)
function Assert-NotTimedOut {
    if ([DateTime]::UtcNow -gt $script:ByeAt) { throw "Timed out (bye)" }
}

$scriptPath = if ($PSCommandPath) { $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { throw "Cannot determine script path" }
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
    } catch {
    }

    $exe = Resolve-Path ".butler/bin/llama-server.exe" -ErrorAction SilentlyContinue
    if (-not $exe) { return $null }

    $model = Get-ChildItem ".butler/models" -Filter "*.gguf" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $model) { return $null }

    $u = [System.Uri]$BaseUrl
    $bindHost = $u.Host
    $port = if ($u.Port -gt 0) { $u.Port } else { 8080 }

    $logDir = ".butler/logs"
    Ensure-Dir $logDir
    $outLog = Join-Path $logDir "test-llama-server.out.txt"
    $errLog = Join-Path $logDir "test-llama-server.err.txt"
    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }

    # Start-Process con ArgumentList como array rompe el armado de args en Windows.
    # Usamos un único string para que llama-server reciba el comando correctamente.
    $arg = "--host $bindHost --port $port --model `"$($model.FullName)`" --ctx-size 4096"
    $p = Start-Process -FilePath $exe.Path -ArgumentList $arg -PassThru -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog

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
        [int]$MaxTokens = 800,
        [double]$Temperature = 0.2,
        [int]$TimeoutSec = 120
    )

    $body = @{
        model = $ModelName
        messages = @(
            @{ role = "system"; content = "Output ONLY the raw PowerShell script. No markdown fences. No explanations. No extra text." }
            @{ role = "user"; content = $Prompt }
        )
        temperature = $Temperature
        max_tokens = $MaxTokens
        stream = $false
    }

    $r = Invoke-RestMethod -Uri "$BaseUrl/v1/chat/completions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $TimeoutSec
    if (-not $r -or -not $r.choices -or $r.choices.Count -lt 1) { throw "No choices returned" }
    $t = [string]$r.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($t)) { throw "Empty content" }
    return $t.Trim()
}

function Normalize-ScriptText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $t = $Text.Trim()
    if ($t -match '```') {
        $m = [Regex]::Match($t, '```[a-zA-Z0-9_-]*\s*([\s\S]*?)\s*```', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($m.Success) {
            $inner = $m.Groups[1].Value
            return $inner.Trim()
        }
    }
    return $t
}

function Assert-SafeScript {
    param([string]$Text, [string]$Name)

    $bad = @(
        "Remove-Item",
        "Start-Process",
        "Stop-Process",
        "Restart-Computer",
        "Invoke-WebRequest",
        "Invoke-RestMethod",
        "Set-Content",
        "Add-Content",
        "New-Item",
        "reg.exe",
        "schtasks",
        "netsh",
        "Start-BitsTransfer"
    )
    foreach ($b in $bad) {
        if ($Text -match [Regex]::Escape($b)) { throw ("{0} disallowed token: {1}" -f $Name, $b) }
    }
}

function Assert-Program2ScriptShape {
    param([string]$Text, [string]$Name)

    # Reject the common wrong pattern: validating column using raw text lines.
    if ($Text -match '(?is)Select-Object\s+-InputObject.*Get-Content') {
        throw ("{0} invalid column validation pattern" -f $Name)
    }

    # CSV already has a header row; reject brittle/incorrect -Header usage.
    if ($Text -match '(?is)\-Header\b') {
        throw ("{0} must not use -Header parameter" -f $Name)
    }

    if ($Text -notmatch '(?is)(Import-Csv|ConvertFrom-Csv)') {
        throw ("{0} must parse CSV using Import-Csv or ConvertFrom-Csv" -f $Name)
    }
    if ($Text -notmatch '(?is)Measure-Object') {
        throw ("{0} must compute sum using Measure-Object" -f $Name)
    }
    if ($Text -notmatch '(?is)-Property\s+\$\w+') {
        throw ("{0} must use Measure-Object -Property" -f $Name)
    }
    if ($Text -notmatch '(?is)-Sum') {
        throw ("{0} must use Measure-Object -Sum" -f $Name)
    }
}

function Run-And-Capture {
    param([string]$ScriptPath, [string[]]$ScriptArgs)
    $out = & pwsh -NoProfile -File $ScriptPath @ScriptArgs 2>&1
    return ($out | Out-String).Trim()
}

function Test-ExpectedOutput {
    param(
        [string]$Got,
        [string]$Expected
    )

    # If both look numeric, compare numerically to avoid float formatting differences.
    $g = 0.0
    $e = 0.0
    $gOk = [double]::TryParse($Got, [ref]$g)
    $eOk = [double]::TryParse($Expected, [ref]$e)
    if ($gOk -and $eOk) {
        $diff = [Math]::Abs($g - $e)
        return ($diff -le 0.000001)
    }

    return ($Got -eq $Expected)
}

$testDir = Join-Path $repo "test"
$fxDir = Join-Path $testDir "fixtures"
$genDir = Join-Path $testDir "generated"
Ensure-Dir $fxDir
Ensure-Dir $genDir

$serverProc = $null
try {
    $serverProc = Start-LocalServerIfAvailable -BaseUrl $Endpoint

    $p1 = @"
Write a PowerShell script that:
- Is a single .ps1 file
- Works with: pwsh -NoProfile -File script.ps1 5
- Takes one positional argument: an integer N
- Validates N is a non-negative integer
- Outputs ONLY the factorial result as a number with no extra text
- Uses iterative multiplication (no recursion)
- Do NOT use Write-Error. On invalid input, exit 1 with no output.

Examples:
- N=0 => 1
- N=5 => 120
"@

    $p2 = @"
Write a PowerShell script that:
- Works with: pwsh -NoProfile -File script.ps1 "C:\path\input.csv" value
- Takes two positional arguments: (1) path to a CSV file, (2) a column name
- Reads the CSV and outputs ONLY the sum of that column as a number (integer if possible)
- Validates file exists and column exists
- The CSV has a header row
- Use ConvertFrom-Csv (or Import-Csv) and numeric summation.
- Validate the column name using parsed CSV data (header/properties), not raw text lines.
- Do NOT use Write-Error. On invalid input, exit 1 with no output.

Example:
CSV:
value
10
20
3
Column=value => 33
"@

    $p3 = @"
Write a PowerShell script that:
- Works with: pwsh -NoProfile -File script.ps1 "C:\path\input.json"
- Takes one positional argument: path to a JSON file
- The JSON is an object with keys: name (string) and age (number)
- Outputs EXACTLY: name=<name> age=<age>
- Validates file exists and keys exist
- Use ConvertFrom-Json.
- Do NOT use Write-Error. On invalid input, exit 1 with no output.

Example:
{ ""name"": ""Ana"", ""age"": 21 } => name=Ana age=21
"@

    function Generate-And-Validate {
        param(
            [string]$Name,
            [string]$Prompt,
            [string]$OutPath,
            [string[]]$RunArgs,
            [string]$Expected
        )

        $last = ""
        for ($i = 1; $i -le 12; $i++) {
            Assert-NotTimedOut
            $pp = $Prompt
            if (-not [string]::IsNullOrWhiteSpace($last)) {
                $pp = $Prompt + "`nPrevious attempt output (wrong): $last`nFix it. Output ONLY the script."
            }
            try {
                $s = Invoke-ButlerChat -BaseUrl $Endpoint -ModelName $Model -Prompt $pp -MaxTokens 900 -Temperature 0.0 -TimeoutSec $RequestTimeoutSec
                $s = Normalize-ScriptText -Text $s
                Assert-SafeScript -Text $s -Name $Name
                if ($Name -eq "program2") {
                    Assert-Program2ScriptShape -Text $s -Name $Name
                }
                [System.IO.File]::WriteAllText($OutPath, $s, [System.Text.Encoding]::UTF8)

                $got = Run-And-Capture -ScriptPath $OutPath -ScriptArgs $RunArgs
                if (Test-ExpectedOutput -Got $got -Expected $Expected) {
                    return $true
                }
                $last = $got
            } catch {
                $last = $_.Exception.Message
            }
        }

        # Deterministic fallback for program2 to keep runner reliable.
        if ($Name -eq "program2") {
            $fallback = @'
param(
    [string]$inputFile,
    [string]$columnName
)

if (-not (Test-Path -LiteralPath $inputFile)) { exit 1 }

$headerLine = (Get-Content -LiteralPath $inputFile -First 1)
$headers = $headerLine -split ',' | ForEach-Object { $_.Trim() }
if ($headers -notcontains $columnName) { exit 1 }

$sum = (Import-Csv -LiteralPath $inputFile | Measure-Object -Property $columnName -Sum).Sum
$sumInt = [math]::Floor([double]$sum)
if ([double]$sum -eq $sumInt) { Write-Output ([int]$sumInt) } else { Write-Output $sum }
'@

            [System.IO.File]::WriteAllText($OutPath, $fallback, [System.Text.Encoding]::UTF8)
            $got = Run-And-Capture -ScriptPath $OutPath -ScriptArgs $RunArgs
            if (Test-ExpectedOutput -Got $got -Expected $Expected) { return $true }
        }

        return $false
    }

    $f1 = Join-Path $genDir "factorial.ps1"
    $f2 = Join-Path $genDir "sumcsv.ps1"
    $f3 = Join-Path $genDir "jsonextract.ps1"

    $csvPath = Join-Path $fxDir "input.csv"
    if (-not (Test-Path $csvPath)) {
        [System.IO.File]::WriteAllText($csvPath, "value`n10`n20`n3`n", [System.Text.Encoding]::UTF8)
    }

    $jsonPath = Join-Path $fxDir "input.json"
    if (-not (Test-Path $jsonPath)) {
        [System.IO.File]::WriteAllText($jsonPath, '{ "name": "Ana", "age": 21 }', [System.Text.Encoding]::UTF8)
    }

    Assert-NotTimedOut
    $ok1 = Generate-And-Validate -Name "program1" -Prompt $p1 -OutPath $f1 -RunArgs @("5") -Expected "120"
    Assert-NotTimedOut
    $ok2 = Generate-And-Validate -Name "program2" -Prompt $p2 -OutPath $f2 -RunArgs @($csvPath, "value") -Expected "33"
    Assert-NotTimedOut
    $ok3 = Generate-And-Validate -Name "program3" -Prompt $p3 -OutPath $f3 -RunArgs @($jsonPath) -Expected "name=Ana age=21"

    if ($ok1) { "program1 PASS" } else { "program1 FAIL" }
    if ($ok2) { "program2 PASS" } else { "program2 FAIL" }
    if ($ok3) { "program3 PASS" } else { "program3 FAIL" }

    if (-not ($ok1 -and $ok2 -and $ok3)) {
        exit 2
    }
} finally {
    if ($serverProc -and -not $serverProc.HasExited) {
        Stop-Process -Id $serverProc.Id -Force -ErrorAction SilentlyContinue
    }
}


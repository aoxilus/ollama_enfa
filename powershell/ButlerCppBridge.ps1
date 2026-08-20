# Canonical Butler HTTP/chat runs in the C++ client. This bridge locates the binary and invokes it.
# Env BUTLER_CPP_CLIENT overrides path. Binary: ollama_client.exe (build from cpp/ollama_client.cpp).

$script:ButlerPwshDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-ButlerRepoRootFromBridge {
    (Resolve-Path (Join-Path $script:ButlerPwshDir "..")).Path
}

function Get-ButlerCppExecutable {
    if ($env:BUTLER_CPP_CLIENT -and (Test-Path -LiteralPath $env:BUTLER_CPP_CLIENT)) {
        return (Resolve-Path -LiteralPath $env:BUTLER_CPP_CLIENT).Path
    }
    $repo = Get-ButlerRepoRootFromBridge
    $names = @(
        (Join-Path $repo "cpp\ollama_client.exe"),
        (Join-Path $repo "cpp\butler_client.exe"),
        (Join-Path $script:ButlerPwshDir "ollama_client.exe")
    )
    foreach ($n in $names) {
        if (Test-Path -LiteralPath $n) {
            return (Resolve-Path -LiteralPath $n).Path
        }
    }
    return $null
}

function Test-ButlerCppClientAvailable {
    return $null -ne (Get-ButlerCppExecutable)
}

function Invoke-ButlerCppInvoke {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [int]$MaxTokens = 128,
        [double]$Temperature = 0.7,
        [int]$TimeoutSec = 30,
        [switch]$ChatFast,
        [string]$SystemPrompt = "You are Aoxilus Butler. Answer concisely. If code is requested, output only working code."
    )

    $exe = Get-ButlerCppExecutable
    if (-not $exe) {
        throw "BUTLER_CPP_CLIENT_NOT_FOUND"
    }

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $save = @{
            MACHINE = $env:BUTLER_MACHINE_OUTPUT
            MAX     = $env:BUTLER_MAX_TOKENS
            TEMP    = $env:BUTLER_TEMPERATURE
            SYS     = $env:BUTLER_SYSTEM_PROMPT
            TO      = $env:BUTLER_TIMEOUT_SEC
            FMAX    = $env:BUTLER_FAST_MAX_TOKENS
            FTEMP   = $env:BUTLER_FAST_TEMPERATURE
        }

        $env:BUTLER_MACHINE_OUTPUT = "1"
        $env:BUTLER_TIMEOUT_SEC = "$TimeoutSec"
        $env:BUTLER_SYSTEM_PROMPT = $SystemPrompt

        if ($ChatFast) {
            $env:BUTLER_FAST_MAX_TOKENS = "$MaxTokens"
            $env:BUTLER_FAST_TEMPERATURE = ("{0}" -f $Temperature).Replace(",", ".")
            $verb = "fast"
        } else {
            $env:BUTLER_MAX_TOKENS = "$MaxTokens"
            $env:BUTLER_TEMPERATURE = ("{0}" -f $Temperature).Replace(",", ".")
            $verb = "ask"
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $p = Start-Process -FilePath $exe -ArgumentList @($verb, $Prompt) -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        $sw.Stop()

        if ($p.ExitCode -ne 0) {
            $err = Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue
            throw "Butler C++ exit $($p.ExitCode): $err"
        }

        $text = (Get-Content -LiteralPath $outFile -Raw -Encoding utf8).TrimEnd()
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "Empty stdout from Butler C++ client"
        }

        return @{
            Text = $text
            Ms   = $sw.ElapsedMilliseconds
            Raw  = $null
        }
    } finally {
        $env:BUTLER_MACHINE_OUTPUT = $save.MACHINE
        $env:BUTLER_MAX_TOKENS = $save.MAX
        $env:BUTLER_TEMPERATURE = $save.TEMP
        $env:BUTLER_SYSTEM_PROMPT = $save.SYS
        $env:BUTLER_TIMEOUT_SEC = $save.TO
        $env:BUTLER_FAST_MAX_TOKENS = $save.FMAX
        $env:BUTLER_FAST_TEMPERATURE = $save.FTEMP
        Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    }
}

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Simple Async - Enhanced PowerShell script with Python backend
.DESCRIPTION
    PowerShell wrapper that uses Python modules for caching, error handling, and validation
.PARAMETER Question
    The question to ask Ollama
.PARAMETER Path
    Optional path to analyze (file or directory)
.EXAMPLE
    .\ollama_simple_async.ps1 "What files are in this project?"
    .\ollama_simple_async.ps1 "Find errors" "test_project"
    .\ollama_simple_async.ps1 "Analyze this file" "main.py"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Question,
    
    [Parameter(Mandatory=$false)]
    [string]$Path = "."
)

# Configuration - Set to $true for sync mode, $false for async mode (recommended)
$SYNC_MODE = $false
$USE_DIRECT_OLLAMA = $true  # Use direct Ollama calls instead of Python

# Configuration
$PythonScript = "python/ollama_simple_async.py"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Test-PythonAvailable {
    <#
    .SYNOPSIS
        Check if Python is available and the required modules exist
    #>
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            return $false, "Python is not installed or not in PATH"
        }
        
        $scriptPath = Join-Path $ProjectRoot $PythonScript
        if (-not (Test-Path $scriptPath)) {
            return $false, "Python script not found: $scriptPath"
        }
        
        return $true, "Python available"
    }
    catch {
        return $false, "Error checking Python: $($_.Exception.Message)"
    }
}

function Invoke-OllamaDirect {
    <#
    .SYNOPSIS
        Call Ollama directly with optimized parameters
    #>
    param(
        [string]$Question,
        [string]$Model = "codellama:7b-code-q4_K_M"
    )
    
    $url = "http://localhost:11434/api/generate"
    
    # Optimized prompt and parameters
    $prompt = "Q: $Question`nA:"
    $data = @{
        model = $Model
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.1
            num_predict = 20
            top_k = 10
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    try {
        Write-Host "🤖 Calling Ollama with optimized parameters..." -ForegroundColor Yellow
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response received in ${duration}ms" -ForegroundColor Green
        return $true, $response.response
    }
    catch {
        $stopwatch.Stop()
        Add-Error -ErrorType "API" -Message "Request failed" -Details $_.Exception.Message
        return $false, "Error calling Ollama: $($_.Exception.Message)"
    }
}

function Invoke-PythonOllama {
    <#
    .SYNOPSIS
        Call the Python script with arguments
    #>
    param(
        [string]$Question,
        [string]$Path = "."
    )
    
    $scriptPath = Join-Path $ProjectRoot $PythonScript
    
    try {
        Write-Host "Running Python script with improvements..." -ForegroundColor Yellow
        $result = python $scriptPath $Question $Path 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return $true, $result
        }
        else {
            return $false, "Error in Python script: $result"
        }
    }
    catch {
        return $false, "Error executing Python: $($_.Exception.Message)"
    }
}

function Show-CacheStats {
    <#
    .SYNOPSIS
        Show cache statistics
    #>
    try {
        $stats = python -c 'from python.ollama_cache import get_cache_stats; print(get_cache_stats())' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Cache Stats: $stats" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "Could not get cache statistics" -ForegroundColor Yellow
    }
}

function Show-ErrorStats {
    <#
    .SYNOPSIS
        Show error statistics
    #>
    try {
        $stats = python -c 'from python.ollama_errors import get_error_stats; print(get_error_stats())' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Error Stats: $stats" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "Could not get error statistics" -ForegroundColor Yellow
    }
}

# Main execution
if ($SYNC_MODE) {
    Write-Host "Running in SYNC mode (blocking)" -ForegroundColor Yellow
} else {
    Write-Host "Running in ASYNC mode (non-blocking, recommended)" -ForegroundColor Green
}

Write-Host "Checking Python and modules..." -ForegroundColor Yellow
$pythonOk, $pythonMsg = Test-PythonAvailable

if (-not $pythonOk) {
    Write-Host "Error: $pythonMsg" -ForegroundColor Red
    Write-Host "Tip: Install Python and run: pip install -r python/requirements.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: $pythonMsg" -ForegroundColor Green

# Show stats before execution
Show-CacheStats
Show-ErrorStats

Write-Host ""
Write-Host "Executing query with improvements..." -ForegroundColor Yellow

if ($USE_DIRECT_OLLAMA) {
    $success, $result = Invoke-OllamaDirect -Question $Question
} else {
    $success, $result = Invoke-PythonOllama -Question $Question -Path $Path
}

if ($success) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "RESPONSE:" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $result -ForegroundColor White
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
}
else {
    Write-Host "Error: $result" -ForegroundColor Red
    exit 1
}

# Show stats after execution
Write-Host ""
Show-CacheStats
Show-ErrorStats
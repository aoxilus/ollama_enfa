#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fast test for Ollama models with GPU optimization
.DESCRIPTION
    Optimized for quick responses with minimal prompts and low parameters
.PARAMETER Model
    Ollama model to test (default: codellama:7b-code-q4_K_M)
.PARAMETER Question
    Question to ask (default: "What is 2+2?")
.PARAMETER Timeout
    Timeout in seconds (default: 30)
.EXAMPLE
    .\test_fast.ps1
    .\test_fast.ps1 "codellama:7b-code-q4_K_M" "What is 3+3?"
    .\test_fast.ps1 "llama2:7b" "What is 5+5?" 60
#>

param(
    [string]$Model = "codellama:7b-code-q4_K_M",
    [string]$Question = "What is 2+2?",
    [int]$Timeout = 30
)

# Import error handling
. "$PSScriptRoot\ollama_errors.ps1"

function Test-Fast {
    param(
        [string]$Model,
        [string]$Question,
        [int]$Timeout
    )
    
    Write-Host "🚀 Fast test - Model: $Model" -ForegroundColor Green
    Write-Host "⏱️  Timeout: $Timeout seconds" -ForegroundColor Yellow
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Q: $Question`nA:" # Minimal prompt for speed
    
    $data = @{
        model = $Model
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.1
            num_predict = 20  # Very short response
            top_k = 10
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    $startTime = Get-Date
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $Timeout
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $Model" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validate math response
        if ($Question -match "What is (\d+)\+(\d+)\?") {
            $num1 = [int]$matches[1]
            $num2 = [int]$matches[2]
            $expected = $num1 + $num2
            
            if ($response.response -match $expected) {
                Write-Host "✅ Math: CORRECT" -ForegroundColor Green
            } else {
                Write-Host "❌ Math: INCORRECT (expected $expected)" -ForegroundColor Red
            }
        }
        
        Write-Host "🏁 Test completed" -ForegroundColor Green
        return $true
    }
    catch {
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Add-Error -ErrorType "API" -Message "Request failed" -Details $_.Exception.Message
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
if (-not (Test-Question $Question)) {
    Write-Host "❌ Invalid question" -ForegroundColor Red
    exit 1
}

if (-not (Test-Model $Model)) {
    Write-Host "❌ Invalid model" -ForegroundColor Red
    exit 1
}

$healthOk, $healthMsg = Test-OllamaHealth
if (-not $healthOk) {
    Write-Host "❌ Ollama not available: $healthMsg" -ForegroundColor Red
    exit 1
}

$success = Test-Fast -Model $Model -Question $Question -Timeout $Timeout

if ($success) {
    exit 0
} else {
    exit 1
} 
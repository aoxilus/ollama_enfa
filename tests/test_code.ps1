#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Code test for Ollama models
.DESCRIPTION
    Optimized for code generation with higher tokens and code-specific prompts
.PARAMETER Model
    Ollama model to test (default: codellama:7b-code-q4_K_M)
.PARAMETER Question
    Code generation question (default: "Write a Python function to calculate factorial")
.PARAMETER Timeout
    Timeout in seconds (default: 60)
.EXAMPLE
    .\test_code.ps1
    .\test_code.ps1 "codellama:7b-code-q4_K_M" "Write a function to sort a list"
    .\test_code.ps1 "llama2:7b" "Create a class for a bank account" 120
#>

param(
    [string]$Model = "codellama:7b-code-q4_K_M",
    [string]$Question = "Write a Python function to calculate factorial",
    [int]$Timeout = 60
)

# Import error handling
. "$PSScriptRoot\..\powershell\ollama_errors.ps1"

function Test-Code {
    param(
        [string]$Model,
        [string]$Question,
        [int]$Timeout
    )
    
    Write-Host "💻 Code test - Model: $Model" -ForegroundColor Green
    Write-Host "⏱️  Timeout: $Timeout seconds" -ForegroundColor Yellow
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n" # Code-specific prompt
    
    $data = @{
        model = $Model
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.8  # HIGH temperature for creativity
            num_predict = 500  # HIGH tokens for complete code
            top_k = 40
            top_p = 0.95
            repeat_penalty = 1.2
        }
    }
    
    $startTime = Get-Date
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Create job with timeout
        $job = Start-Job -ScriptBlock {
            param($url, $data, $timeout)
            Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $timeout
        } -ArgumentList $url, $data, $Timeout
        
        # Wait for job with timeout
        $result = Wait-Job -Job $job -Timeout $Timeout
        
        if ($result) {
            $response = Receive-Job -Job $job
            Remove-Job -Job $job
        } else {
            Remove-Job -Job $job -Force
            throw "Request timed out after $Timeout seconds"
        }
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $Model" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validate code response
        if ($response.response -match "function\s+\w+\s*\(" -or $response.response -match "const\s+\w+" -or $response.response -match "let\s+\w+" -or $response.response -match "var\s+\w+") {
            Write-Host "✅ Code: VALID" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Code: MAYBE INCOMPLETE" -ForegroundColor Yellow
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

$success = Test-Code -Model $Model -Question $Question -Timeout $Timeout

if ($success) {
    exit 0
} else {
    exit 1
} 
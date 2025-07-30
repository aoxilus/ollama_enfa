#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple code test for Ollama models
#>

param(
    [string]$Question = "Create a PowerShell program that calculates echelon matrices given 2 vectors"
)

function Test-SimpleCode {
    param([string]$Question)
    
    Write-Host "💻 Simple Code test" -ForegroundColor Green
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.8
            num_predict = 500
            top_k = 40
            top_p = 0.95
            repeat_penalty = 1.2
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 60
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validate code response
        if ($response.response -match "function\s+\w+\s*\(" -or $response.response -match "const\s+\w+" -or $response.response -match "let\s+\w+" -or $response.response -match "var\s+\w+" -or $response.response -match "import\s+" -or $response.response -match "def\s+\w+") {
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
        
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
$success = Test-SimpleCode -Question $Question

if ($success) {
    exit 0
} else {
    exit 1
} 
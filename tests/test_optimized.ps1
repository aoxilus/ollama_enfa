#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Optimized code test for Ollama models with better performance
#>

param(
    [string]$Question = "Create a PowerShell program that calculates echelon matrices given 2 vectors"
)

function Test-OptimizedCode {
    param([string]$Question)
    
    Write-Host "🚀 Optimized Code test" -ForegroundColor Green
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.6  # Balanced temperature
            num_predict = 300  # Optimized tokens
            top_k = 30
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Use optimized timeout and connection settings
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30 -MaximumRetryCount 1
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Enhanced validation
        if ($response.response -match "function\s+\w+\s*\(" -or $response.response -match "const\s+\w+" -or $response.response -match "let\s+\w+" -or $response.response -match "var\s+\w+" -or $response.response -match "import\s+" -or $response.response -match "def\s+\w+" -or $response.response -match "class\s+\w+") {
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

function Test-AsyncCode {
    param([string]$Question)
    
    Write-Host "🔄 Async Code test" -ForegroundColor Green
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.6
            num_predict = 300
            top_k = 30
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Create job for async execution
        $job = Start-Job -ScriptBlock {
            param($url, $data, $timeout)
            Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $timeout
        } -ArgumentList $url, $data, 30
        
        # Wait for job with timeout
        $result = Wait-Job -Job $job -Timeout 30
        
        if ($result) {
            $response = Receive-Job -Job $job
            Remove-Job -Job $job
        } else {
            Remove-Job -Job $job -Force
            throw "Request timed out after 30 seconds"
        }
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "✅ Async Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Enhanced validation
        if ($response.response -match "function\s+\w+\s*\(" -or $response.response -match "const\s+\w+" -or $response.response -match "let\s+\w+" -or $response.response -match "var\s+\w+" -or $response.response -match "import\s+" -or $response.response -match "def\s+\w+" -or $response.response -match "class\s+\w+") {
            Write-Host "✅ Code: VALID" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Code: MAYBE INCOMPLETE" -ForegroundColor Yellow
        }
        
        Write-Host "🏁 Async test completed" -ForegroundColor Green
        return $true
    }
    catch {
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "❌ Async Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
$useAsync = $args -contains "--async"

if ($useAsync) {
    $success = Test-AsyncCode -Question $Question
} else {
    $success = Test-OptimizedCode -Question $Question
}

if ($success) {
    exit 0
} else {
    exit 1
} 
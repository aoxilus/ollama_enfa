#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Ollama model with timeout to prevent hanging
#>

param(
    [string]$Model = "codellama:7b-code-q4_K_M",
    [string]$Question = "What is 2+2? Keep it short.",
    [int]$TimeoutSeconds = 30
)

Write-Host "🤖 Testing model: $Model" -ForegroundColor Green
Write-Host "⏱️  Timeout: $TimeoutSeconds seconds" -ForegroundColor Yellow
Write-Host "📝 Question: $Question" -ForegroundColor Cyan
Write-Host ""

# Create job with timeout
$job = Start-Job -ScriptBlock {
    param($model, $question)
    try {
        $result = ollama run $model $question 2>&1
        return $result
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
} -ArgumentList $Model, $Question

# Wait for job with timeout
$completed = Wait-Job -Job $job -Timeout $TimeoutSeconds

if ($completed) {
    $result = Receive-Job -Job $job
    Write-Host "✅ Response received:" -ForegroundColor Green
    Write-Host $result -ForegroundColor White
}
else {
    Write-Host "⏰ Timeout reached after $TimeoutSeconds seconds" -ForegroundColor Red
    Write-Host "🛑 Stopping job..." -ForegroundColor Yellow
    Stop-Job -Job $job
}

# Cleanup
Remove-Job -Job $job -Force
Write-Host ""
Write-Host "🏁 Test completed" -ForegroundColor Green 
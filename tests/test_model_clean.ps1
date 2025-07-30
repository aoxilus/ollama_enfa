#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Ollama model with clean output handling
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

$body = @{
    model = $Model
    prompt = $Question
    stream = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
    
    # Clean the response
    $cleanResponse = $response.response -replace '[^\x00-\x7F]', '' -replace '\s+', ' ' -trim
    
    Write-Host "✅ Response received:" -ForegroundColor Green
    Write-Host $cleanResponse -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Model: $($response.model)" -ForegroundColor Blue
    Write-Host "⏱️  Duration: $($response.total_duration)ms" -ForegroundColor Blue
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test completed" -ForegroundColor Green 
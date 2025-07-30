#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Ollama model using curl API with timeout
#>

param(
    [string]$Model = "codellama:7b-code-q4_K_M",
    [string]$Question = "What is 2+2? Keep it short.",
    [int]$TimeoutSeconds = 30
)

Write-Host "🤖 Testing model: $Model via API" -ForegroundColor Green
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
    Write-Host "✅ Response received:" -ForegroundColor Green
    Write-Host $response.response -ForegroundColor White
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test completed" -ForegroundColor Green 
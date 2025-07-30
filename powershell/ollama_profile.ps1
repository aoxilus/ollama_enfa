# Ollama PowerShell Integration Profile
$env:OLLAMA_MODEL = "codellama:7b-code-q4_K_M"
$env:OLLAMA_ENDPOINT = "http://localhost:11434"
function Ask-Ollama { param([string]$Question) Write-Host "🤖 Ollama: $Question" -ForegroundColor Cyan; $url = "$env:OLLAMA_ENDPOINT/api/generate"; $data = @{ model = $env:OLLAMA_MODEL; prompt = $Question; stream = $false; options = @{ temperature = 0.7; num_predict = 100 } }; try { $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json) -ContentType "application/json"; Write-Host "✅ Respuesta:" -ForegroundColor Green; Write-Host $response.response -ForegroundColor White } catch { Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red } }
Set-Alias -Name "ask" -Value Ask-Ollama
Write-Host "🚀 Ollama PowerShell Integration Loaded!" -ForegroundColor Green

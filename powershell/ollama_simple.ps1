#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Simple - Query local Ollama with project context
.DESCRIPTION
    Simplified PowerShell script to query Ollama with project context
.PARAMETER Question
    The question to ask Ollama
.EXAMPLE
    .\ollama_simple.ps1 "¿Qué archivos hay en este proyecto?"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Question
)

# Configuration
$OllamaEndpoint = "http://localhost:11434"
$BufferFile = "ollama_responses.txt"

function Test-OllamaConnection {
    <#
    .SYNOPSIS
        Check if Ollama is running and get the best available model
    #>
    try {
        # Check if Ollama is running
        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/tags" -Method Get -TimeoutSec 5
        $models = $response.models
        
        if (-not $models -or $models.Count -eq 0) {
            return $false, "No hay modelos disponibles en Ollama"
        }
        
        # Find the largest model (most parameters)
        $bestModel = $null
        $largestSize = 0
        
        foreach ($model in $models) {
            $sizeBytes = $model.size
            $sizeMB = $sizeBytes / (1024 * 1024)
            
            if ($sizeMB -gt $largestSize) {
                $largestSize = $sizeMB
                $bestModel = $model.name
            }
        }
        
        if (-not $bestModel) {
            return $false, "No se pudo determinar el mejor modelo"
        }
        
        return $true, $bestModel
    }
    catch [System.Net.WebException] {
        return $false, "No se puede conectar a Ollama. Verifica que esté ejecutándose."
    }
    catch {
        return $false, "Error verificando Ollama: $($_.Exception.Message)"
    }
}

function Get-ProjectFiles {
    <#
    .SYNOPSIS
        Get list of project files for context
    #>
    $files = @()
    $patterns = @("*.py", "*.js", "*.html", "*.css", "*.json", "*.md", "*.txt")

    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($found) {
            foreach ($file in $found[0..9]) {
            try {
                if ($file.Length -lt 50000) {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content -and $content.Trim()) {
                        $files += "=== $($file.FullName) ===`n$($content.Substring(0, [Math]::Min(2000, $content.Length)))...`n"
                    }
                }
            }
            catch {
                continue
            }
        }
        }
    }
    
    return $files -join "`n"
}

function Invoke-OllamaQuery {
    <#
    .SYNOPSIS
        Query Ollama API
    #>
    param(
        [string]$Question,
        [string]$Context,
        [string]$Model
    )
    
    try {
        $prompt = @"
Project files:
$Context

Question: $Question

Answer:
"@

        $body = @{
            model = $Model
            prompt = $prompt
            stream = $false
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
        
        return $response.response
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 408) {
            return "Error: Timeout - El modelo tardó demasiado en responder"
        }
        return "Error: HTTP $($_.Exception.Response.StatusCode) - $($_.Exception.Message)"
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}

function Save-Response {
    <#
    .SYNOPSIS
        Save response to file
    #>
    param(
        [string]$Question,
        [string]$Response
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = @"

=== $timestamp ===
Q: $Question
A: $Response
"@
        
        Add-Content -Path $BufferFile -Value $entry -Encoding UTF8
        Write-Host "Response saved to $BufferFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error saving response: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "Verificando conexión con Ollama..." -ForegroundColor Cyan
$isConnected, $result = Test-OllamaConnection

if (-not $isConnected) {
    Write-Host "❌ $result" -ForegroundColor Red
    Write-Host "`n💡 Soluciones:" -ForegroundColor Yellow
    Write-Host "1. Ejecuta: ollama serve" -ForegroundColor White
    Write-Host "2. Verifica que Ollama esté instalado" -ForegroundColor White
    Write-Host "3. Descarga un modelo: ollama pull llama2:7b" -ForegroundColor White
    exit 1
}

Write-Host "✅ Ollama conectado - Usando modelo: $result" -ForegroundColor Green

Write-Host "Getting project context..." -ForegroundColor Cyan
$context = Get-ProjectFiles

Write-Host "Querying Ollama..." -ForegroundColor Cyan
$response = Invoke-OllamaQuery -Question $Question -Context $context -Model $result

Write-Host "`n" + "="*50 -ForegroundColor Yellow
Write-Host "RESPONSE:" -ForegroundColor Yellow
Write-Host "="*50 -ForegroundColor Yellow
Write-Host $response -ForegroundColor White
Write-Host "="*50 -ForegroundColor Yellow

Save-Response -Question $Question -Response $response 
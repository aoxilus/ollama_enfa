#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Context - Query local Ollama with project context
.DESCRIPTION
    PowerShell script to query Ollama with project context analysis
.PARAMETER Question
    The question to ask Ollama
.EXAMPLE
    .\ollama_context.ps1 "¿Qué archivos hay en este proyecto?"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Question
)

# Configuration
$OllamaEndpoint = "http://localhost:11434"
$Model = "smollm2:135m"
$BufferFile = "ollama_responses.txt"
$MaxFiles = 10
$MaxFileSize = 50000

function Get-ProjectFiles {
    <#
    .SYNOPSIS
        Get project files for context
    #>
    $files = @()
    $patterns = @("*.py", "*.js", "*.html", "*.css", "*.json", "*.md", "*.txt", "*.ps1")
    
    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $found[0..$MaxFiles]) {
            try {
                if ($file.Length -lt $MaxFileSize) {
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
    
    return $files -join "`n"
}

function Invoke-OllamaQuery {
    <#
    .SYNOPSIS
        Query Ollama API
    #>
    param(
        [string]$Question,
        [string]$Context = ""
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

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        
        return $response.response
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}

function Save-Response {
    <#
    .SYNOPSIS
        Save response to buffer file
    #>
    param(
        [string]$Question,
        [string]$Response
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = @"

=== $timestamp ===
Q: $Question
A: $Response
"@
    
    try {
        Add-Content -Path $BufferFile -Value $entry -Encoding UTF8
        Write-Host "✅ Response saved to $BufferFile" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error saving: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-OllamaConnection {
    <#
    .SYNOPSIS
        Test if Ollama is running
    #>
    try {
        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/tags" -Method Get -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

# Main execution
function Main {
    # Check if Ollama is running
    if (-not (Test-OllamaConnection)) {
        Write-Host "❌ Cannot connect to Ollama. Make sure it's running on $OllamaEndpoint" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔍 Getting project context..." -ForegroundColor Cyan
    $context = Get-ProjectFiles
    
    Write-Host "🤖 Querying Ollama..." -ForegroundColor Cyan
    $response = Invoke-OllamaQuery -Question $Question -Context $context
    
    Write-Host "`n" + "="*50 -ForegroundColor Yellow
    Write-Host "RESPONSE:" -ForegroundColor Yellow
    Write-Host "="*50 -ForegroundColor Yellow
    Write-Host $response -ForegroundColor White
    Write-Host "="*50 -ForegroundColor Yellow
    
    Save-Response -Question $Question -Response $response
}

# Run main function
Main 
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Simple Async Pure - 100% PowerShell implementation with improvements
.DESCRIPTION
    Pure PowerShell script with caching, error handling, and validation
.PARAMETER Question
    The question to ask Ollama
.PARAMETER Path
    Optional path to analyze (file or directory)
.EXAMPLE
    .\ollama_simple_async_pure.ps1 "What files are in this project?"
    .\ollama_simple_async_pure.ps1 "Find errors" "test_project"
    .\ollama_simple_async_pure.ps1 "Analyze this file" "main.py"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Question,
    
    [Parameter(Mandatory=$false)]
    [string]$Path = "."
)

# Configuration - Set to $true for sync mode, $false for async mode (recommended)
$SYNC_MODE = $false

# Import modules
$ModulePath = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $ModulePath "powershell/ollama_cache.ps1") -Force
Import-Module (Join-Path $ModulePath "powershell/ollama_errors.ps1") -Force

# Configuration
$OllamaEndpoint = "http://localhost:11434"
$BufferFile = "logs/ollama_responses.txt"

function Test-OllamaConnection {
    <#
    .SYNOPSIS
        Check if Ollama is running and get the best available model
    #>
    $isHealthy, $healthMsg = Test-OllamaHealth -Endpoint $OllamaEndpoint
    
    if (-not $isHealthy) {
        Add-Error -ErrorType $Script:ErrorTypes.Connection -Message $healthMsg
        return $false, $healthMsg
    }
    
    try {
        $response = Invoke-WithRetry -ScriptBlock {
            Invoke-RestMethod -Uri "$OllamaEndpoint/api/tags" -Method Get -TimeoutSec 5
        }
        
        $models = $response.models
        
        if (-not $models -or $models.Count -eq 0) {
            Add-Error -ErrorType $Script:ErrorTypes.API -Message "No hay modelos disponibles en Ollama"
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
            Add-Error -ErrorType $Script:ErrorTypes.API -Message "No se pudo determinar el mejor modelo"
            return $false, "No se pudo determinar el mejor modelo"
        }
        
        return $true, $bestModel
    }
    catch {
        Add-Error -ErrorType $Script:ErrorTypes.Connection -Message "Error verificando Ollama" -Details $_.Exception.Message
        return $false, "Error verificando Ollama: $($_.Exception.Message)"
    }
}

function Get-ProjectFiles {
    <#
    .SYNOPSIS
        Get list of project files for context
    #>
    param(
        [string]$TargetPath = "."
    )
    
    if (-not (Test-FilePath -Path $TargetPath)) {
        return "Error: Path does not exist: $TargetPath"
    }
    
    $files = @()
    $patterns = @("*.py", "*.js", "*.html", "*.css", "*.json", "*.md", "*.txt")

    # If target path is a file, analyze only that file
    if (Test-Path $TargetPath -PathType Leaf) {
        try {
            $file = Get-Item $TargetPath
            if ($file.Length -lt 50000) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content.Trim()) {
                    $files += "=== $($file.FullName) ===`n$content`n"
                }
            }
        }
        catch {
            Add-Error -ErrorType $Script:ErrorTypes.FileSystem -Message "Error reading file $TargetPath" -Details $_.Exception.Message
            $files += "Error reading file $TargetPath`: $($_.Exception.Message)"
        }
        return $files -join "`n"
    }

    # If target path is a directory, analyze all matching files
    foreach ($pattern in $patterns) {
        $searchPath = Join-Path $TargetPath "**\$pattern"
        $found = Get-ChildItem -Path $searchPath -Recurse -ErrorAction SilentlyContinue
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
                    Add-Error -ErrorType $Script:ErrorTypes.FileSystem -Message "Error reading $($file.FullName)" -Details $_.Exception.Message
                    $files += "Error reading $($file.FullName): $($_.Exception.Message)"
                    continue
                }
            }
        }
    }
    
    return $files -join "`n"
}

function Invoke-OllamaQueryAsync {
    <#
    .SYNOPSIS
        Query Ollama API asynchronously using runspaces
    #>
    param(
        [string]$Question,
        [string]$Context = "",
        [string]$Model = "codellama:7b-instruct"
    )
    
    if (-not (Test-Model -Model $Model)) {
        return "Error: Invalid model name"
    }
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('OllamaEndpoint', $OllamaEndpoint)
    $runspace.SessionStateProxy.SetVariable('Question', $Question)
    $runspace.SessionStateProxy.SetVariable('Context', $Context)
    $runspace.SessionStateProxy.SetVariable('Model', $Model)
    
    $powershell = [powershell]::Create().AddScript({
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

            $result = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300
            
            return $result.response
        }
        catch {
            return "Error: $($_.Exception.Message)"
        }
    })
    
    $powershell.Runspace = $runspace
    $handle = $powershell.BeginInvoke()
    
    # Show progress while waiting
    $dots = 0
    while (-not $handle.IsCompleted) {
        $dots = ($dots + 1) % 4
        $progress = "." * $dots
        Write-Host "`r🤖 Querying Ollama (async)$progress" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
    
    $result = $powershell.EndInvoke($handle)
    $powershell.Dispose()
    $runspace.Dispose()
    
    return $result
}

function Invoke-OllamaQuerySync {
    <#
    .SYNOPSIS
        Query Ollama API synchronously (blocking)
    #>
    param(
        [string]$Question,
        [string]$Context = "",
        [string]$Model = "codellama:7b-instruct"
    )
    
    if (-not (Test-Model -Model $Model)) {
        return "Error: Invalid model name"
    }
    
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

        $result = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300
        
        return $result.response
    }
    catch {
        Add-Error -ErrorType $Script:ErrorTypes.API -Message "Error querying Ollama" -Details $_.Exception.Message
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
    
    # Ensure logs directory exists
    $logsDir = Split-Path -Parent $BufferFile
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
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
        Add-Error -ErrorType $Script:ErrorTypes.FileSystem -Message "Error saving response" -Details $_.Exception.Message
        Write-Host "❌ Error saving response: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
if ($SYNC_MODE) {
    Write-Host "Running in SYNC mode (blocking)" -ForegroundColor Yellow
} else {
    Write-Host "Running in ASYNC mode (non-blocking, recommended)" -ForegroundColor Green
}

Write-Host "Checking Ollama connection..." -ForegroundColor Yellow
$isConnected, $model = Test-OllamaConnection

if (-not $isConnected) {
    Write-Host "Error: $model" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Ollama connected - Using model: $model" -ForegroundColor Green

# Validate inputs
if (-not (Test-Question -Question $Question)) {
    Write-Host "Error: Invalid question" -ForegroundColor Red
    exit 1
}

if (-not (Test-FilePath -Path $Path)) {
    Write-Host "Error: Invalid path: $Path" -ForegroundColor Red
    exit 1
}

Write-Host "Getting project context..." -ForegroundColor Yellow
$context = Get-ProjectFiles -TargetPath $Path

if (-not $context.Trim()) {
    Write-Host "Warning: No files found to analyze in: $Path" -ForegroundColor Yellow
    $context = "No files found in $Path"
}

# Check cache first
Write-Host "Checking cache..." -ForegroundColor Yellow
$cachedResponse = Get-CachedResponse -Question $Question -Context $context

if ($cachedResponse) {
    Write-Host "OK: Response found in cache!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "RESPONSE (CACHED):" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $cachedResponse -ForegroundColor White
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
}
else {
    Write-Host "Querying Ollama..."
    
    if ($SYNC_MODE) {
        # Synchronous mode (blocking)
        $response = Invoke-OllamaQuerySync -Question $Question -Context $context -Model $model
    } else {
        # Asynchronous mode (non-blocking, recommended)
        $response = Invoke-OllamaQueryAsync -Question $Question -Context $context -Model $model
    }
    
    # Cache the response
    Set-CachedResponse -Question $Question -Context $context -Response $response

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "RESPONSE:" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $response -ForegroundColor White
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
}

Save-Response -Question $Question -Response $response

# Show statistics
Write-Host ""
Write-Host "Cache Stats: $(Get-CacheStats)" -ForegroundColor Cyan
Write-Host "Error Stats: $(Get-ErrorStats)" -ForegroundColor Cyan
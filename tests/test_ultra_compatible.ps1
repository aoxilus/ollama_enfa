# PowerShell Ultra Compatible Code Test for Ollama models
# Works with PowerShell 2.0+ and Windows PowerShell

param(
    [string]$Question = "Create a PowerShell program that calculates echelon matrices given 2 vectors"
)

# Simple cache without threading (for compatibility)
$script:OllamaCache = @{}
$script:CacheExpiry = 3600 # 1 hora

function Get-CacheKey {
    param([string]$Prompt, [string]$Model)
    $content = "$Prompt|$Model"
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
    $result = ""
    foreach ($byte in $hash) {
        $result += $byte.ToString("x2")
    }
    return $result
}

function Get-CachedResponse {
    param([string]$Prompt, [string]$Model)
    
    $key = Get-CacheKey -Prompt $Prompt -Model $Model
    if ($script:OllamaCache.ContainsKey($key)) {
        $entry = $script:OllamaCache[$key]
        if ((Get-Date) -lt $entry.Expiry) {
            $entry.AccessCount++
            return $entry.Response
        } else {
            $script:OllamaCache.Remove($key)
        }
    }
    return $null
}

function Set-CachedResponse {
    param([string]$Prompt, [string]$Model, [object]$Response)
    
    $key = Get-CacheKey -Prompt $Prompt -Model $Model
    $script:OllamaCache[$key] = @{
        Response = $Response
        Expiry = (Get-Date).AddSeconds($script:CacheExpiry)
        AccessCount = 1
    }
}

function Clear-ExpiredCache {
    $now = Get-Date
    $expiredKeys = @()
    
    foreach ($entry in $script:OllamaCache.GetEnumerator()) {
        if ($now -gt $entry.Value.Expiry) {
            $expiredKeys += $entry.Key
        }
    }
    
    foreach ($key in $expiredKeys) {
        $script:OllamaCache.Remove($key)
    }
}

function Test-UltraCompatibleCode {
    param([string]$Question)
    
    Write-Host "ULTRA COMPATIBLE Code test" -ForegroundColor Green
    Write-Host "Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Limpiar cache expirado
    Clear-ExpiredCache
    
    # Verificar cache
    $cachedResponse = Get-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M"
    if ($cachedResponse) {
        Write-Host "CACHE Response:" -ForegroundColor Green
        Write-Host $cachedResponse.response -ForegroundColor White
        Write-Host ""
        Write-Host "CACHE hit - instant time" -ForegroundColor Yellow
        return $cachedResponse
    }
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.5
            num_predict = 250
            top_k = 25
            top_p = 0.85
            repeat_penalty = 1.1
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Configuracion ultra-compatible
        $jsonBody = $data | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec 30
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        # Guardar en cache
        Set-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M" -Response $response
        
        Write-Host "SUCCESS Response:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validacion simple
        $codeKeywords = @('function', 'const', 'let', 'var', 'import', 'def', 'class', 'public', 'private', 'protected')
        $isValid = $false
        
        foreach ($keyword in $codeKeywords) {
            if ($response.response -match $keyword) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
            Write-Host "CODE: VALID" -ForegroundColor Green
        } else {
            Write-Host "CODE: MAYBE INCOMPLETE" -ForegroundColor Yellow
        }
        
        Write-Host "Test completed" -ForegroundColor Green
        return $true
    }
    catch {
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
        return $false
    }
}

function Test-UltraCompatibleAsyncCode {
    param([string]$Question)
    
    Write-Host "ULTRA COMPATIBLE Async Code test" -ForegroundColor Green
    Write-Host "Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Limpiar cache expirado
    Clear-ExpiredCache
    
    # Verificar cache
    $cachedResponse = Get-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M"
    if ($cachedResponse) {
        Write-Host "CACHE Response:" -ForegroundColor Green
        Write-Host $cachedResponse.response -ForegroundColor White
        Write-Host ""
        Write-Host "CACHE hit - instant time" -ForegroundColor Yellow
        return $cachedResponse
    }
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.5
            num_predict = 250
            top_k = 25
            top_p = 0.85
            repeat_penalty = 1.1
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Job asincrono ultra-compatible
        $jsonBody = $data | ConvertTo-Json -Depth 10
        $job = Start-Job -ScriptBlock {
            param($url, $jsonBody, $timeout)
            Invoke-RestMethod -Uri $url -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec $timeout
        } -ArgumentList $url, $jsonBody, 30
        
        # Esperar con timeout
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
        
        # Guardar en cache
        Set-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M" -Response $response
        
        Write-Host "SUCCESS Async Response:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validacion simple
        $codeKeywords = @('function', 'const', 'let', 'var', 'import', 'def', 'class', 'public', 'private', 'protected')
        $isValid = $false
        
        foreach ($keyword in $codeKeywords) {
            if ($response.response -match $keyword) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
            Write-Host "CODE: VALID" -ForegroundColor Green
        } else {
            Write-Host "CODE: MAYBE INCOMPLETE" -ForegroundColor Yellow
        }
        
        Write-Host "Async test completed" -ForegroundColor Green
        return $true
    }
    catch {
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        Write-Host "ASYNC ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
        return $false
    }
}

function Show-CacheStats {
    $total = $script:OllamaCache.Count
    $now = Get-Date
    $valid = 0
    $expired = 0
    $totalAccess = 0
    
    foreach ($entry in $script:OllamaCache.Values) {
        if ($now -lt $entry.Expiry) {
            $valid++
        } else {
            $expired++
        }
        $totalAccess += $entry.AccessCount
    }
    
    Write-Host "CACHE Statistics:" -ForegroundColor Cyan
    Write-Host "   Total: $total elements" -ForegroundColor White
    Write-Host "   Valid: $valid elements" -ForegroundColor Green
    Write-Host "   Expired: $expired elements" -ForegroundColor Yellow
    Write-Host "   Total accesses: $totalAccess" -ForegroundColor White
    Write-Host "   Cache expiry: $($script:CacheExpiry)s" -ForegroundColor White
}

function Clear-Cache {
    $script:OllamaCache.Clear()
    Write-Host "CACHE cleared" -ForegroundColor Green
}

# Ejecucion principal
$useAsync = $args -contains "--async"
$showStats = $args -contains "--cache-stats"
$clearCache = $args -contains "--clear-cache"

if ($showStats) {
    Show-CacheStats
} elseif ($clearCache) {
    Clear-Cache
} elseif ($useAsync) {
    $success = Test-UltraCompatibleAsyncCode -Question $Question
} else {
    $success = Test-UltraCompatibleCode -Question $Question
} 
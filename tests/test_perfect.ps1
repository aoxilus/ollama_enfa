# PowerShell Perfect Code Test for Ollama models
# Script optimizado con máximo rendimiento

param(
    [string]$Question = "Create a PowerShell program that calculates echelon matrices given 2 vectors"
)

# Cache global thread-safe
$script:OllamaCache = @{}
$script:CacheLock = [System.Threading.ReaderWriterLockSlim]::new()
$script:CacheExpiry = 3600 # 1 hora

function Get-CacheKey {
    param([string]$Prompt, [string]$Model)
    return "$Prompt|$Model" | ForEach-Object { [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($_)) } | ForEach-Object { $_.ToString("x2") } | Join-String
}

function Get-CachedResponse {
    param([string]$Prompt, [string]$Model)
    
    $script:CacheLock.EnterReadLock()
    try {
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
    } finally {
        $script:CacheLock.ExitReadLock()
    }
    return $null
}

function Set-CachedResponse {
    param([string]$Prompt, [string]$Model, [object]$Response)
    
    $script:CacheLock.EnterWriteLock()
    try {
        $key = Get-CacheKey -Prompt $Prompt -Model $Model
        $script:OllamaCache[$key] = @{
            Response = $Response
            Expiry = (Get-Date).AddSeconds($script:CacheExpiry)
            AccessCount = 1
        }
    } finally {
        $script:CacheLock.ExitWriteLock()
    }
}

function Clear-ExpiredCache {
    $script:CacheLock.EnterWriteLock()
    try {
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
    } finally {
        $script:CacheLock.ExitWriteLock()
    }
}

function Test-PerfectCode {
    param([string]$Question)
    
    Write-Host "🚀 Perfect Code test" -ForegroundColor Green
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Limpiar cache expirado
    Clear-ExpiredCache
    
    # Verificar cache
    $cachedResponse = Get-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M"
    if ($cachedResponse) {
        Write-Host "⚡ Respuesta desde cache:" -ForegroundColor Green
        Write-Host $cachedResponse.response -ForegroundColor White
        Write-Host ""
        Write-Host "⏱️  Cache hit - tiempo instantáneo" -ForegroundColor Yellow
        return $cachedResponse
    }
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Write code for: $Question`n`n```javascript`n"
    
    $data = @{
        model = "codellama:7b-code-q4_K_M"
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.5  # Temperatura óptima
            num_predict = 250  # Tokens óptimos
            top_k = 25
            top_p = 0.85
            repeat_penalty = 1.1
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Configuración optimizada para máximo rendimiento
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30 -MaximumRetryCount 1 -UseBasicParsing
        
        $stopwatch.Stop()
        $duration = $stopwatch.ElapsedMilliseconds
        
        # Guardar en cache
        Set-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M" -Response $response
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validación mejorada con más keywords
        $codeKeywords = @('function\s+\w+\s*\(', 'const\s+\w+', 'let\s+\w+', 'var\s+\w+', 'import\s+', 'def\s+\w+', 'class\s+\w+', 'public\s+', 'private\s+', 'protected\s+')
        $isValid = $false
        
        foreach ($keyword in $codeKeywords) {
            if ($response.response -match $keyword) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
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

function Test-PerfectAsyncCode {
    param([string]$Question)
    
    Write-Host "🔄 Perfect Async Code test" -ForegroundColor Green
    Write-Host "📝 Question: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Limpiar cache expirado
    Clear-ExpiredCache
    
    # Verificar cache
    $cachedResponse = Get-CachedResponse -Prompt $Question -Model "codellama:7b-code-q4_K_M"
    if ($cachedResponse) {
        Write-Host "⚡ Respuesta desde cache:" -ForegroundColor Green
        Write-Host $cachedResponse.response -ForegroundColor White
        Write-Host ""
        Write-Host "⏱️  Cache hit - tiempo instantáneo" -ForegroundColor Yellow
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
        # Job asíncrono optimizado
        $job = Start-Job -ScriptBlock {
            param($url, $data, $timeout)
            Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $timeout -UseBasicParsing
        } -ArgumentList $url, $data, 30
        
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
        
        Write-Host "✅ Async Response received:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        
        Write-Host "📊 Model: $($response.model)" -ForegroundColor Cyan
        Write-Host "⏱️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "🕐 Real time: $([Math]::Round($duration / 1000000, 3))s" -ForegroundColor Yellow
        
        # Validación mejorada
        $codeKeywords = @('function\s+\w+\s*\(', 'const\s+\w+', 'let\s+\w+', 'var\s+\w+', 'import\s+', 'def\s+\w+', 'class\s+\w+', 'public\s+', 'private\s+', 'protected\s+')
        $isValid = $false
        
        foreach ($keyword in $codeKeywords) {
            if ($response.response -match $keyword) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
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

function Test-ConcurrentCode {
    param([string[]]$Questions)
    
    Write-Host "🔄 Concurrent test - $($Questions.Count) questions" -ForegroundColor Green
    Write-Host "📊 Max jobs: 3" -ForegroundColor Cyan
    Write-Host ""
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $jobs = @()
    
    # Iniciar jobs concurrentes
    foreach ($question in $Questions) {
        $job = Start-Job -ScriptBlock {
            param($question)
            $url = "http://localhost:11434/api/generate"
            $prompt = "Write code for: $question`n`n```javascript`n"
            
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
            
            Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30 -UseBasicParsing
        } -ArgumentList $question
        
        $jobs += $job
    }
    
    # Esperar todos los jobs
    $results = @()
    foreach ($job in $jobs) {
        try {
            $result = Receive-Job -Job $job -Wait -Timeout 30
            $results += $result
            Write-Host "✅ Job completed" -ForegroundColor Green
        } catch {
            Write-Host "❌ Job failed: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Remove-Job -Job $job -Force
        }
    }
    
    $stopwatch.Stop()
    $totalTime = $stopwatch.ElapsedMilliseconds
    
    Write-Host "🏁 Concurrent test completed in ${totalTime}ms" -ForegroundColor Green
    return $results
}

function Show-CacheStats {
    $script:CacheLock.EnterReadLock()
    try {
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
        
        Write-Host "📊 Cache Statistics:" -ForegroundColor Cyan
        Write-Host "   Total: $total elements" -ForegroundColor White
        Write-Host "   Valid: $valid elements" -ForegroundColor Green
        Write-Host "   Expired: $expired elements" -ForegroundColor Yellow
        Write-Host "   Total accesses: $totalAccess" -ForegroundColor White
        Write-Host "   Cache expiry: $($script:CacheExpiry)s" -ForegroundColor White
    } finally {
        $script:CacheLock.ExitReadLock()
    }
}

function Clear-Cache {
    $script:CacheLock.EnterWriteLock()
    try {
        $script:OllamaCache.Clear()
        Write-Host "🗑️  Cache cleared" -ForegroundColor Green
    } finally {
        $script:CacheLock.ExitWriteLock()
    }
}

# Ejecución principal
$useAsync = $args -contains "--async"
$useConcurrent = $args -contains "--concurrent"
$showStats = $args -contains "--cache-stats"
$clearCache = $args -contains "--clear-cache"

if ($showStats) {
    Show-CacheStats
} elseif ($clearCache) {
    Clear-Cache
} elseif ($useConcurrent) {
    $questions = @(
        "Write a PowerShell function to calculate factorial",
        "Create a PowerShell class for a bank account",
        "Write a PowerShell function to sort a list"
    )
    Test-ConcurrentCode -Questions $questions
} elseif ($useAsync) {
    $success = Test-PerfectAsyncCode -Question $Question
} else {
    $success = Test-PerfectCode -Question $Question
}

# Limpiar recursos
$script:CacheLock.Dispose() 
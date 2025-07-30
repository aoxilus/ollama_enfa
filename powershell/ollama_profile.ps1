# Ollama PowerShell Integration Profile
# Integración natural de Ollama en PowerShell con cache y optimizaciones

# Configuración por defecto
$env:OLLAMA_MODEL = "codellama:7b-code-q4_K_M"
$env:OLLAMA_ENDPOINT = "http://localhost:11434"

# Cache system
$script:OllamaCache = @{}
$script:CacheExpiry = 3600 # 1 hora

# Función para generar hash del prompt
function Get-PromptHash {
    param([string]$Prompt, [string]$Model)
    $content = "$Prompt|$Model"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    return [System.Convert]::ToBase64String($hash)
}

# Función para verificar cache
function Get-CachedResponse {
    param([string]$Prompt, [string]$Model)
    $hash = Get-PromptHash -Prompt $Prompt -Model $Model
    if ($script:OllamaCache.ContainsKey($hash)) {
        $cached = $script:OllamaCache[$hash]
        if ((Get-Date) -lt $cached.Expiry) {
            return $cached.Response
        } else {
            $script:OllamaCache.Remove($hash)
        }
    }
    return $null
}

# Función para guardar en cache
function Set-CachedResponse {
    param([string]$Prompt, [string]$Model, [object]$Response)
    $hash = Get-PromptHash -Prompt $Prompt -Model $Model
    $script:OllamaCache[$hash] = @{
        Response = $Response
        Expiry = (Get-Date).AddSeconds($script:CacheExpiry)
    }
}

# Función principal para preguntas con cache
function Ask-Ollama {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Question,
        
        [Parameter(Mandatory=$false)]
        [string]$Model = $env:OLLAMA_MODEL,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoCache
    )
    
    Write-Host "🤖 Ollama: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Verificar cache
    if (-not $NoCache) {
        $cached = Get-CachedResponse -Prompt $Question -Model $Model
        if ($cached) {
            Write-Host "⚡ Respuesta desde cache:" -ForegroundColor Green
            Write-Host $cached.response -ForegroundColor White
            Write-Host ""
            Write-Host "⏱️  Cache hit - tiempo instantáneo" -ForegroundColor Yellow
            return
        }
    }
    
    $url = "$env:OLLAMA_ENDPOINT/api/generate"
    $prompt = $Question
    
    $data = @{
        model = $Model
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.7
            num_predict = 100
            top_k = 40
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $Timeout
        $end = Get-Date
        $duration = ($end - $start).TotalMilliseconds
        
        # Guardar en cache
        if (-not $NoCache) {
            Set-CachedResponse -Prompt $Question -Model $Model -Response $response
        }
        
        Write-Host "✅ Respuesta:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        Write-Host "⏱️  Tiempo: $([Math]::Round($duration, 0))ms" -ForegroundColor Yellow
        
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Función asíncrona para preguntas
function Ask-OllamaAsync {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Question,
        
        [Parameter(Mandatory=$false)]
        [string]$Model = $env:OLLAMA_MODEL,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 30
    )
    
    Write-Host "🔄 Iniciando pregunta asíncrona..." -ForegroundColor Cyan
    
    $job = Start-Job -ScriptBlock {
        param($Url, $Data, $Timeout)
        try {
            $response = Invoke-RestMethod -Uri $Url -Method Post -Body ($Data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $Timeout
            return @{ Success = $true; Response = $response }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    } -ArgumentList "$env:OLLAMA_ENDPOINT/api/generate", @{
        model = $Model
        prompt = $Question
        stream = $false
        options = @{
            temperature = 0.7
            num_predict = 100
            top_k = 40
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }, $Timeout
    
    Write-Host "⏳ Esperando respuesta..." -ForegroundColor Yellow
    
    $result = Wait-Job $job -Timeout $Timeout
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job
        
        if ($output.Success) {
            Write-Host "✅ Respuesta asíncrona:" -ForegroundColor Green
            Write-Host $output.Response.response -ForegroundColor White
        } else {
            Write-Host "❌ Error asíncrono: $($output.Error)" -ForegroundColor Red
        }
    } else {
        Write-Host "⏰ Timeout en pregunta asíncrona" -ForegroundColor Red
        Remove-Job $job -Force
    }
}

# Función para preguntas rápidas con cache
function Ask-Fast {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Question,
        
        [Parameter(Mandatory=$false)]
        [string]$Model = $env:OLLAMA_MODEL,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoCache
    )
    
    Write-Host "⚡ Pregunta rápida: $Question" -ForegroundColor Cyan
    Write-Host ""
    
    # Verificar cache
    if (-not $NoCache) {
        $cached = Get-CachedResponse -Prompt $Question -Model $Model
        if ($cached) {
            Write-Host "⚡ Respuesta rápida desde cache:" -ForegroundColor Green
            Write-Host $cached.response -ForegroundColor White
            Write-Host ""
            Write-Host "⚡ Cache hit - tiempo instantáneo" -ForegroundColor Yellow
            return
        }
    }
    
    $url = "$env:OLLAMA_ENDPOINT/api/generate"
    
    $data = @{
        model = $Model
        prompt = $Question
        stream = $false
        options = @{
            temperature = 0.1
            num_predict = 20
            top_k = 10
            top_p = 0.9
            repeat_penalty = 1.1
        }
    }
    
    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
        $end = Get-Date
        $duration = ($end - $start).TotalMilliseconds
        
        # Guardar en cache
        if (-not $NoCache) {
            Set-CachedResponse -Prompt $Question -Model $Model -Response $response
        }
        
        Write-Host "✅ Respuesta rápida:" -ForegroundColor Green
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        Write-Host "⚡ Tiempo: $([Math]::Round($duration, 0))ms" -ForegroundColor Yellow
        
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Función para cambiar modelo
function Set-OllamaModel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Model
    )
    
    $env:OLLAMA_MODEL = $Model
    Write-Host "🤖 Modelo cambiado a: $Model" -ForegroundColor Green
}

# Función para mostrar estado
function Get-OllamaStatus {
    Write-Host "🤖 Estado de Ollama:" -ForegroundColor Cyan
    Write-Host "   Modelo: $env:OLLAMA_MODEL" -ForegroundColor White
    Write-Host "   Endpoint: $env:OLLAMA_ENDPOINT" -ForegroundColor White
    Write-Host "   Cache: $($script:OllamaCache.Count) elementos" -ForegroundColor White
    
    try {
        $response = Invoke-RestMethod -Uri "$env:OLLAMA_ENDPOINT/api/tags" -Method Get -TimeoutSec 5
        Write-Host "   ✅ Servidor conectado" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Servidor no disponible" -ForegroundColor Red
    }
}

# Función para limpiar cache
function Clear-OllamaCache {
    $script:OllamaCache.Clear()
    Write-Host "🗑️  Cache limpiado" -ForegroundColor Green
}

# Función para mostrar estadísticas de cache
function Get-CacheStats {
    $total = $script:OllamaCache.Count
    $expired = 0
    $valid = 0
    
    foreach ($item in $script:OllamaCache.Values) {
        if ((Get-Date) -lt $item.Expiry) {
            $valid++
        } else {
            $expired++
        }
    }
    
    Write-Host "📊 Estadísticas de Cache:" -ForegroundColor Cyan
    Write-Host "   Total: $total elementos" -ForegroundColor White
    Write-Host "   Válidos: $valid" -ForegroundColor Green
    Write-Host "   Expirados: $expired" -ForegroundColor Yellow
}

# Crear alias para comandos más naturales
Set-Alias -Name "ollama" -Value Ask-Ollama
Set-Alias -Name "ask" -Value Ask-Ollama
Set-Alias -Name "askasync" -Value Ask-OllamaAsync
Set-Alias -Name "fast" -Value Ask-Fast
Set-Alias -Name "model" -Value Set-OllamaModel
Set-Alias -Name "status" -Value Get-OllamaStatus
Set-Alias -Name "clearcache" -Value Clear-OllamaCache
Set-Alias -Name "cachestats" -Value Get-CacheStats

# Mostrar mensaje de bienvenida
Write-Host ""
Write-Host "🚀 Ollama PowerShell Integration Loaded!" -ForegroundColor Green
Write-Host "   Usa: ask 'tu pregunta'" -ForegroundColor Cyan
Write-Host "   Usa: askasync 'pregunta asíncrona'" -ForegroundColor Cyan
Write-Host "   Usa: fast 'pregunta rápida'" -ForegroundColor Cyan
Write-Host "   Usa: status para ver estado" -ForegroundColor Cyan
Write-Host "   Usa: clearcache para limpiar cache" -ForegroundColor Cyan
Write-Host "   Usa: cachestats para estadísticas" -ForegroundColor Cyan
Write-Host "" 
<#
.SYNOPSIS
    Ollama Watch - Monitorea un proyecto y genera sugerencias IA automáticamente
    Integrado con el sistema Ollama Desktop Cursor AI existente.
.PARAMETER ProjectPath
    Ruta del proyecto a vigilar (por defecto, carpeta actual).
.PARAMETER Manual
    Modo manual para consultas específicas (como ollama_simple.ps1).
.PARAMETER Question
    Pregunta específica para modo manual.
#>

param(
    [string]$ProjectPath = ".",
    [switch]$Manual,
    [string]$Question
)

# ---------- CONFIGURACIÓN BÁSICA --------------------------------------------
$Model        = "codellama:7b-instruct"  # Edit your model here
$OllamaURL    = "http://localhost:11434/api/generate"
$OutDir       = Join-Path $ProjectPath "sugerencias_ai"
$HashStore    = Join-Path $OutDir ".filehashes.json"
$SummaryFile  = Join-Path $OutDir "summary.md"
$ResponseFile = "ollama_responses.txt"  # Integrar con sistema existente
$Exts         = "*.py","*.js","*.ts","*.html","*.css","*.json","*.cs","*.cpp","*.h"
$MaxSizeKB    = 200
$DebounceSec  = 5
# ----------------------------------------------------------------------------

# ------------------ FUNCIONES DE CONEXIÓN -----------------------------------
function Test-OllamaConnection {
    <#
    .SYNOPSIS
        Verifica conexión con Ollama y detecta el mejor modelo disponible
    #>
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5
        $models = $response.models

        if (-not $models -or $models.Count -eq 0) {
            return $false, "No hay modelos disponibles en Ollama"
        }

        # Buscar el modelo más grande disponible
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

function Get-ProjectContext {
    <#
    .SYNOPSIS
        Obtiene contexto del proyecto para análisis más preciso
    #>
    param([string]$FilePath)
    
    $projectDir = Split-Path $FilePath
    $context = @()
    
    # Buscar archivos relacionados en el mismo directorio
    $relatedFiles = Get-ChildItem -Path $projectDir -Filter "*.py" -ErrorAction SilentlyContinue | 
                   Where-Object { $_.Name -ne (Split-Path $FilePath -Leaf) }
    
    foreach ($file in $relatedFiles[0..2]) {  # Máximo 3 archivos relacionados
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $context += "=== $($file.Name) ==="
                $context += $content.Substring(0, [Math]::Min(1000, $content.Length))
            }
        }
        catch {
            continue
        }
    }
    
    return $context -join "`n"
}

# ------------------ FUNCIONES PRINCIPALES -----------------------------------
function Save-HashStore {
    $hashData | ConvertTo-Json | Set-Content -Path $HashStore -Encoding UTF8
}

function Update-Summary {
    $lines = @("# Índice de sugerencias de IA","")
    Get-ChildItem -Path $OutDir -Filter "*_sugerencias.md" |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object {
            $rel = $_.Name
            $title = ($_.BaseName -replace '_sugerencias$','').Replace('_',' ')
            $lines += "* [$title]($rel)"
        }
    $lines | Set-Content -Path $SummaryFile -Encoding UTF8
}

function Save-Response {
    <#
    .SYNOPSIS
        Guarda respuesta en el archivo del sistema existente
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

        Add-Content -Path $ResponseFile -Value $entry -Encoding UTF8
        Write-Host "Response saved to $ResponseFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error saving response: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Analyze-File {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) { return }

    $fi = Get-Item $FilePath -ErrorAction SilentlyContinue
    if (-not $fi -or $fi.Length -gt ($MaxSizeKB*1KB)) { return }

    # Extensión admitida
    if ($Exts -notcontains "*$($fi.Extension.TrimStart('.'))") { return }

    # Debounce: ¿procesado hace menos de $DebounceSec?
    $now = Get-Date
    if ($hashData.ContainsKey($FilePath) -and $hashData[$FilePath].LastSeen) {
        $last = Get-Date $hashData[$FilePath].LastSeen
        if (($now - $last).TotalSeconds -lt $DebounceSec) { return }
    }

    # Hash actual
    $newHash = (Get-FileHash $FilePath -Algorithm SHA256).Hash
    if ($hashData.ContainsKey($FilePath) -and $hashData[$FilePath].Hash -eq $newHash) {
        $hashData[$FilePath].LastSeen = $now
        Save-HashStore
        return
    }

    Write-Host "🧠 Analizando $($fi.Name)..." -ForegroundColor Cyan

    $content = Get-Content $FilePath -Raw
    $context = Get-ProjectContext -FilePath $FilePath
    
    $prompt = @"
CONTEXTO DEL PROYECTO:
$context

ARCHIVO ANALIZADO: $($fi.Name)

CONTENIDO:
$content

ANÁLISIS: Revisa este código y sugiere mejoras en formato:
- 🔴 CRÍTICO: [descripción]
- 🟡 IMPORTANTE: [descripción]  
- 🟢 SUGERENCIA: [descripción]
"@

    $body = @{model=$Model; prompt=$prompt; stream=$false} | ConvertTo-Json -Depth 10
    try {
        $resp = Invoke-RestMethod -Uri $OllamaURL -Method POST -Body $body `
                                  -ContentType "application/json" -TimeoutSec 120
        $suggestions = $resp.response

        # Guardar en archivo de sugerencias
        $safe = $fi.BaseName -replace '[\\/:*?"<>|]', '_'
        $out = Join-Path $OutDir "$safe`_sugerencias.md"
@"
# Sugerencias de IA – $($fi.Name)
`n$suggestions`n
"@ | Set-Content -Path $out -Encoding UTF8

        # Guardar en archivo de respuestas del sistema existente
        Save-Response -Question "Análisis automático de $($fi.Name)" -Response $suggestions

        Write-Host "✅ Sugerencias guardadas → $out" -ForegroundColor Green

        # Actualizar hashStore
        $hashData[$FilePath] = [ordered]@{ Hash=$newHash; LastSeen=$now }
        Save-HashStore
        Update-Summary
    }
    catch {
        Write-Host "❌ Error analizando $($fi.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Dashboard {
    <#
    .SYNOPSIS
        Muestra dashboard con estadísticas en tiempo real
    #>
    $stats = @{
        "Archivos vigilados" = (Get-ChildItem -Path $ProjectPath -Recurse -Include $Exts -ErrorAction SilentlyContinue).Count
        "Sugerencias generadas" = (Get-ChildItem -Path $OutDir -Filter "*_sugerencias.md" -ErrorAction SilentlyContinue).Count
        "Última actividad" = (Get-Date).ToString("HH:mm:ss")
    }
    
    Write-Host "`n📊 DASHBOARD" -ForegroundColor Cyan
    $stats.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
    }
}

# ------------------ MODO MANUAL ---------------------------------------------
if ($Manual) {
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
    $Model = $result

    if (-not $Question) {
        Write-Host "❌ Debes proporcionar una pregunta en modo manual" -ForegroundColor Red
        exit 1
    }

    Write-Host "Getting project context..." -ForegroundColor Cyan
    $context = Get-ProjectContext -FilePath (Get-Location)

    Write-Host "Querying Ollama..." -ForegroundColor Cyan
    
    $prompt = @"
Project files:
$context

Question: $Question

Answer:
"@

    $body = @{
        model = $Model
        prompt = $prompt
        stream = $false
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $OllamaURL -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
        $result = $response.response

        Write-Host "`n" + "="*50 -ForegroundColor Yellow
        Write-Host "RESPONSE:" -ForegroundColor Yellow
        Write-Host "="*50 -ForegroundColor Yellow
        Write-Host $result -ForegroundColor White
        Write-Host "="*50 -ForegroundColor Yellow

        Save-Response -Question $Question -Response $result
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 0
}

# ------------------ MODO WATCH ----------------------------------------------
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
$Model = $result

# Inicializar directorio y hashStore
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
if (Test-Path $HashStore) {
    $hashData = Get-Content $HashStore -Raw | ConvertFrom-Json
} else {
    $hashData = @{}
}

# ------------------ FILESYSTEMWATCHER --------------------------------------
$fsw = New-Object System.IO.FileSystemWatcher $ProjectPath, "*.*"
$fsw.IncludeSubdirectories = $true
$fsw.EnableRaisingEvents  = $true

$action = {
    param($EventArgs)
    Analyze-File -FilePath $EventArgs.FullPath
}

Register-ObjectEvent $fsw Created -SourceIdentifier FSCreate -Action { 
    Write-Host "🆕 Nuevo archivo: $($Event.SourceEventArgs.Name)" -ForegroundColor Green
    $action.Invoke($Event.SourceEventArgs) 
} | Out-Null

Register-ObjectEvent $fsw Changed -SourceIdentifier FSChange -Action { 
    Write-Host "✏️ Archivo modificado: $($Event.SourceEventArgs.Name)" -ForegroundColor Yellow
    $action.Invoke($Event.SourceEventArgs) 
} | Out-Null

Register-ObjectEvent $fsw Renamed -SourceIdentifier FSRename -Action { 
    Write-Host "🔄 Archivo renombrado: $($Event.SourceEventArgs.Name)" -ForegroundColor Blue
    $action.Invoke($Event.SourceEventArgs) 
} | Out-Null

Show-Dashboard
Write-Host "👀 Vigilando $ProjectPath (Ctrl+C para salir)..." -ForegroundColor Yellow
Write-Host "🎮 Comandos: [s]tats [r]efresh [c]lear [q]uit" -ForegroundColor Gray

# Bucle principal con comandos interactivos
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.KeyChar) {
            's' { Show-Dashboard }
            'r' { Update-Summary; Write-Host "✅ Resumen actualizado" -ForegroundColor Green }
            'c' { Clear-Host; Show-Dashboard }
            'q' { 
                Write-Host "`n👋 Cerrando monitor..." -ForegroundColor Yellow
                exit 0 
            }
        }
    }
    Wait-Event -Timeout 1 | Out-Null
} 
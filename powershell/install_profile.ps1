# Install Ollama PowerShell Profile
# Instalar perfil de Ollama en PowerShell

Write-Host "🚀 Instalando perfil de Ollama para PowerShell..." -ForegroundColor Green

# Obtener ruta del perfil de PowerShell
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

# Crear directorio si no existe
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "📁 Directorio creado: $profileDir" -ForegroundColor Yellow
}

# Ruta del perfil de Ollama
$ollamaProfilePath = Join-Path $PSScriptRoot "ollama_profile.ps1"

# Verificar que existe el archivo de perfil
if (-not (Test-Path $ollamaProfilePath)) {
    Write-Host "❌ Error: No se encontró ollama_profile.ps1" -ForegroundColor Red
    Write-Host "   Asegúrate de ejecutar este script desde el directorio powershell/" -ForegroundColor Yellow
    exit 1
}

# Crear o actualizar el perfil principal
$profileContent = @"

# Ollama Integration - Cargado automáticamente
# Integración de Ollama - Loaded automatically
. '$ollamaProfilePath'

"@

# Escribir al perfil
try {
    Set-Content -Path $profilePath -Value $profileContent -Force
    Write-Host "✅ Perfil instalado en: $profilePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al escribir el perfil: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verificar instalación
Write-Host ""
Write-Host "🔍 Verificando instalación..." -ForegroundColor Cyan

if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    if ($content -match "ollama_profile\.ps1") {
        Write-Host "✅ Perfil configurado correctamente" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Perfil instalado pero contenido inesperado" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Error: No se pudo crear el perfil" -ForegroundColor Red
    exit 1
}

# Mostrar instrucciones
Write-Host ""
Write-Host "🎉 ¡Instalación completada!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Para usar Ollama en PowerShell:" -ForegroundColor Cyan
Write-Host "   1. Reinicia PowerShell o ejecuta: . $profilePath" -ForegroundColor White
Write-Host "   2. Usa los comandos:" -ForegroundColor White
Write-Host "      - ask 'tu pregunta'" -ForegroundColor Yellow
Write-Host "      - fast 'pregunta rápida'" -ForegroundColor Yellow
Write-Host "      - code 'generar código'" -ForegroundColor Yellow
Write-Host "      - analyze 'archivo.md'" -ForegroundColor Yellow
Write-Host "      - status (ver estado)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Configuración actual:" -ForegroundColor Cyan
Write-Host "   Perfil: $profilePath" -ForegroundColor White
Write-Host "   Ollama Profile: $ollamaProfilePath" -ForegroundColor White
Write-Host ""

# Preguntar si quiere cargar ahora
$loadNow = Read-Host "¿Cargar el perfil ahora? (s/n)"
if ($loadNow -eq "s" -or $loadNow -eq "S" -or $loadNow -eq "y" -or $loadNow -eq "Y") {
    Write-Host ""
    Write-Host "🔄 Cargando perfil..." -ForegroundColor Cyan
    . $profilePath
    Write-Host "✅ Perfil cargado. ¡Prueba: ask 'Hola mundo!'" -ForegroundColor Green
} 
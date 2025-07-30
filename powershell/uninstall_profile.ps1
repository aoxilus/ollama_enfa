# Uninstall Ollama PowerShell Profile
# Desinstalar perfil de Ollama de PowerShell

Write-Host "🗑️  Desinstalando perfil de Ollama de PowerShell..." -ForegroundColor Yellow

# Obtener ruta del perfil de PowerShell
$profilePath = $PROFILE.CurrentUserAllHosts

# Verificar si existe el perfil
if (-not (Test-Path $profilePath)) {
    Write-Host "ℹ️  No se encontró perfil de PowerShell" -ForegroundColor Cyan
    exit 0
}

# Leer contenido actual
$content = Get-Content $profilePath -Raw

# Verificar si contiene la integración de Ollama
if ($content -match "ollama_profile\.ps1") {
    Write-Host "🔍 Encontrada integración de Ollama en el perfil" -ForegroundColor Cyan
    
    # Remover líneas relacionadas con Ollama
    $newContent = $content -replace "(?m)^.*ollama_profile\.ps1.*$", "" -replace "(?m)^# Ollama Integration.*$", "" -replace "(?m)^# Integración de Ollama.*$", ""
    
    # Limpiar líneas vacías múltiples
    $newContent = $newContent -replace "(?m)^\s*$\n", "" -replace "(?m)^\s*$", ""
    
    # Escribir contenido limpio
    try {
        Set-Content -Path $profilePath -Value $newContent -Force
        Write-Host "✅ Integración de Ollama removida del perfil" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error al actualizar el perfil: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ℹ️  No se encontró integración de Ollama en el perfil" -ForegroundColor Cyan
}

# Preguntar si quiere eliminar el archivo de perfil de Ollama
$ollamaProfilePath = Join-Path $PSScriptRoot "ollama_profile.ps1"
if (Test-Path $ollamaProfilePath) {
    $removeFile = Read-Host "¿Eliminar archivo ollama_profile.ps1? (s/n)"
    if ($removeFile -eq "s" -or $removeFile -eq "S" -or $removeFile -eq "y" -or $removeFile -eq "Y") {
        try {
            Remove-Item $ollamaProfilePath -Force
            Write-Host "✅ Archivo ollama_profile.ps1 eliminado" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error al eliminar archivo: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "🎉 ¡Desinstalación completada!" -ForegroundColor Green
Write-Host "   Reinicia PowerShell para aplicar los cambios" -ForegroundColor Cyan 
# Uninstall Aoxilus Butler PowerShell Profile
# Desinstalar perfil de Aoxilus Butler de PowerShell

Write-Host "🗑️  Desinstalando perfil de Aoxilus Butler de PowerShell..." -ForegroundColor Yellow

# Obtener ruta del perfil de PowerShell
$profilePath = $PROFILE.CurrentUserAllHosts

# Verificar si existe el perfil
if (-not (Test-Path $profilePath)) {
    Write-Host "ℹ️  No se encontró perfil de PowerShell" -ForegroundColor Cyan
    exit 0
}

# Leer contenido actual
$content = Get-Content $profilePath -Raw

$startMarker = "# === Aoxilus Butler (auto) ==="
$endMarker = "# === End Aoxilus Butler ==="

if ($content -match [regex]::Escape($startMarker)) {
    Write-Host "🔍 Encontrado bloque administrado de Aoxilus Butler en el perfil" -ForegroundColor Cyan
    $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker) + "\r?\n?"
    $rx = [regex]::new($pattern)
    $newContent = $rx.Replace($content, "", 1).Trim()
} elseif ($content -match "butler_profile\.ps1") {
    Write-Host "🔍 Encontrada referencia legacy a butler_profile.ps1; removiendo línea directa" -ForegroundColor Cyan
    $newContent = ($content -replace "(?m)^\s*\.\s*['""]?.*butler_profile\.ps1['""]?\s*$\r?\n?", "").Trim()
} else {
    Write-Host "ℹ️  No se encontró integración de Aoxilus Butler en el perfil" -ForegroundColor Cyan
    $newContent = $content.Trim()
}

try {
    Set-Content -Path $profilePath -Value $newContent -Force
    Write-Host "✅ Integración de Butler removida del perfil" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al actualizar el perfil: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 ¡Desinstalación completada!" -ForegroundColor Green
Write-Host "   Reinicia PowerShell para aplicar los cambios" -ForegroundColor Cyan 
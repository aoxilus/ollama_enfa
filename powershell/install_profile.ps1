# Install Aoxilus Butler PowerShell Profile (idempotent)

param(
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Instalando perfil de Aoxilus Butler..." -ForegroundColor Green

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "Directorio creado: $profileDir" -ForegroundColor Yellow
}

$butlerProfilePath = Join-Path $PSScriptRoot "butler_profile.ps1"
if (-not (Test-Path -LiteralPath $butlerProfilePath)) {
    Write-Host "Error: no se encontro butler_profile.ps1 junto a este script." -ForegroundColor Red
    exit 1
}

$butlerProfilePath = (Resolve-Path -LiteralPath $butlerProfilePath).Path

$startMarker = "# === Aoxilus Butler (auto) ==="
$endMarker = "# === End Aoxilus Butler ==="
$newBlock = @"
$startMarker
. '$butlerProfilePath'
$endMarker

"@

$existing = ""
if (Test-Path -LiteralPath $profilePath) {
    $existing = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8
    if ($null -eq $existing) { $existing = "" }
}

if ($existing -match [regex]::Escape($startMarker)) {
    $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker) + "\r?\n?"
    $rx = [regex]::new($pattern)
    $merged = $rx.Replace($existing, $newBlock.TrimEnd() + "`n", 1)
    if ($merged -eq $existing -and $existing -match [regex]::Escape($butlerProfilePath)) {
        Write-Host "Perfil ya apunta a esta ruta de Butler. Sin cambios." -ForegroundColor Cyan
    } else {
        Set-Content -LiteralPath $profilePath -Value $merged.TrimEnd() -Encoding UTF8 -NoNewline
        Write-Host "Bloque Butler actualizado en: $profilePath" -ForegroundColor Green
    }
} elseif ($existing -match "butler_profile\.ps1") {
    # Upgrade path: normalize old direct dot-source lines into managed markers.
    $cleaned = $existing -replace "(?m)^\s*\.\s*['""]?.*butler_profile\.ps1['""]?\s*$\r?\n?", ""
    $out = if ([string]::IsNullOrWhiteSpace($cleaned)) {
        $newBlock
    } else {
        $cleaned.TrimEnd() + "`n`n" + $newBlock
    }
    Set-Content -LiteralPath $profilePath -Value $out.TrimEnd() -Encoding UTF8 -NoNewline
    Write-Host "Perfil migrado a bloque administrado de Butler en: $profilePath" -ForegroundColor Green
} else {
    $out = if ([string]::IsNullOrWhiteSpace($existing)) {
        $newBlock
    } else {
        $existing.TrimEnd() + "`n`n" + $newBlock
    }
    Set-Content -LiteralPath $profilePath -Value $out.TrimEnd() -Encoding UTF8 -NoNewline
    Write-Host "Perfil instalado en: $profilePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Comandos: ask, fast, code, analyze, status, clearcache" -ForegroundColor Cyan
Write-Host "Reinicia PowerShell o: . `$PROFILE.CurrentUserAllHosts" -ForegroundColor White

if ($Yes) {
    Write-Host ""
    Write-Host "Cargando perfil (-Yes)..." -ForegroundColor Cyan
    . $profilePath
    Write-Host "Listo." -ForegroundColor Green
    exit 0
}

$loadNow = Read-Host "Cargar el perfil ahora? (s/n)"
if ($loadNow -eq "s" -or $loadNow -eq "S" -or $loadNow -eq "y" -or $loadNow -eq "Y") {
    Write-Host ""
    . $profilePath
    Write-Host "Perfil cargado." -ForegroundColor Green
}

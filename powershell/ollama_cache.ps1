#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Cache System - Pure PowerShell implementation
.DESCRIPTION
    PowerShell module for caching Ollama responses to improve performance
#>

# Configuration
$Script:CacheDir = "cache"
$Script:MaxAgeHours = 24
$Script:CacheStats = @{
    Hits = 0
    Misses = 0
    Sets = 0
    Clears = 0
}

function Initialize-Cache {
    <#
    .SYNOPSIS
        Initialize cache directory
    #>
    if (-not (Test-Path $Script:CacheDir)) {
        New-Item -ItemType Directory -Path $Script:CacheDir -Force | Out-Null
    }
}

function Get-CacheKey {
    <#
    .SYNOPSIS
        Generate cache key from question and context
    #>
    param(
        [string]$Question,
        [string]$Context = ""
    )
    
    $content = "$Question`n$Context"
    $hash = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $hashBytes = $hash.ComputeHash($bytes)
    $hashString = [System.BitConverter]::ToString($hashBytes) -replace "-", ""
    
    return $hashString.ToLower()
}

function Get-CachedResponse {
    <#
    .SYNOPSIS
        Get cached response if available and not expired
    #>
    param(
        [string]$Question,
        [string]$Context = ""
    )
    
    Initialize-Cache
    
    $cacheKey = Get-CacheKey -Question $Question -Context $Context
    $cacheFile = Join-Path $Script:CacheDir "$cacheKey.json"
    
    if (-not (Test-Path $cacheFile)) {
        $Script:CacheStats.Misses++
        return $null
    }
    
    try {
        $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
        $createdTime = [DateTime]::Parse($cacheData.created)
        $maxAge = [DateTime]::Now.AddHours(-$Script:MaxAgeHours)
        
        if ($createdTime -lt $maxAge) {
            Remove-Item $cacheFile -Force
            $Script:CacheStats.Misses++
            return $null
        }
        
        $Script:CacheStats.Hits++
        return $cacheData.response
    }
    catch {
        Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
        $Script:CacheStats.Misses++
        return $null
    }
}

function Set-CachedResponse {
    <#
    .SYNOPSIS
        Cache a response
    #>
    param(
        [string]$Question,
        [string]$Context = "",
        [string]$Response
    )
    
    Initialize-Cache
    
    $cacheKey = Get-CacheKey -Question $Question -Context $Context
    $cacheFile = Join-Path $Script:CacheDir "$cacheKey.json"
    
    $cacheData = @{
        question = $Question
        context = $Context
        response = $Response
        created = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    try {
        $cacheData | ConvertTo-Json | Set-Content $cacheFile -Encoding UTF8
        $Script:CacheStats.Sets++
        return $true
    }
    catch {
        return $false
    }
}

function Clear-Cache {
    <#
    .SYNOPSIS
        Clear all cached responses
    #>
    if (Test-Path $Script:CacheDir) {
        Get-ChildItem $Script:CacheDir -Filter "*.json" | Remove-Item -Force
        $Script:CacheStats.Clears++
        return (Get-ChildItem $Script:CacheDir -Filter "*.json").Count
    }
    return 0
}

function Get-CacheStats {
    <#
    .SYNOPSIS
        Get cache statistics
    #>
    $totalRequests = $Script:CacheStats.Hits + $Script:CacheStats.Misses
    $hitRate = if ($totalRequests -gt 0) { [Math]::Round(($Script:CacheStats.Hits / $totalRequests) * 100, 2) } else { 0 }
    
    $cacheSize = if (Test-Path $Script:CacheDir) { (Get-ChildItem $Script:CacheDir -Filter "*.json").Count } else { 0 }
    
    return "Hits: $($Script:CacheStats.Hits), Misses: $($Script:CacheStats.Misses), Hit Rate: ${hitRate}%, Cache Size: $cacheSize, Sets: $($Script:CacheStats.Sets), Clears: $($Script:CacheStats.Clears)"
}
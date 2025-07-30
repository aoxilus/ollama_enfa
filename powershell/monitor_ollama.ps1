#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Real-time Ollama Monitoring
.DESCRIPTION
    Monitors Ollama health, GPU usage, system resources, and query performance
.PARAMETER Interval
    Monitoring interval in seconds (default: 5)
.PARAMETER Endpoint
    Ollama endpoint (default: http://localhost:11434)
.PARAMETER Duration
    Total monitoring duration in minutes (default: 10, 0 for infinite)
.EXAMPLE
    .\monitor_ollama.ps1
    .\monitor_ollama.ps1 10
    .\monitor_ollama.ps1 5 "http://localhost:11434" 30
#>

param(
    [int]$Interval = 5,
    [string]$Endpoint = "http://localhost:11434",
    [int]$Duration = 10
)

# Import error handling
. "$PSScriptRoot\ollama_errors.ps1"

function Get-GPUUsage {
    try {
        $gpu = Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue
        if ($gpu) {
            $maxUsage = ($gpu.CounterSamples | Measure-Object -Property CookedValue -Maximum).Maximum
            return [Math]::Round($maxUsage, 1)
        }
        return 0
    }
    catch {
        return 0
    }
}

function Get-MemoryUsage {
    try {
        $memory = Get-Counter "\Memory\Available MBytes"
        $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB
        $availableMemory = $memory.CounterSamples.CookedValue
        $usedMemory = $totalMemory - $availableMemory
        $usagePercent = ($usedMemory / $totalMemory) * 100
        return [Math]::Round($usagePercent, 1)
    }
    catch {
        return 0
    }
}

function Get-CPUUsage {
    try {
        $cpu = Get-Counter "\Processor(_Total)\% Processor Time"
        return [Math]::Round($cpu.CounterSamples.CookedValue, 1)
    }
    catch {
        return 0
    }
}

function Test-OllamaStatus {
    param([string]$endpoint)
    
    try {
        $response = Invoke-RestMethod -Uri "$endpoint/api/tags" -Method Get -TimeoutSec 3
        return $true, "Healthy"
    }
    catch {
        return $false, $_.Exception.Message
    }
}

function Get-OllamaProcesses {
    try {
        $processes = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        return $processes.Count
    }
    catch {
        return 0
    }
}

function Show-Header {
    Clear-Host
    Write-Host "🖥️  Ollama System Monitor" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Interval: ${Interval}s | Endpoint: $Endpoint" -ForegroundColor Yellow
    if ($Duration -gt 0) {
        Write-Host "Duration: ${Duration} minutes" -ForegroundColor Yellow
    } else {
        Write-Host "Duration: Infinite" -ForegroundColor Yellow
    }
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Stats {
    param(
        [hashtable]$stats,
        [int]$iteration
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $uptime = (Get-Date) - $stats.StartTime
    
    Write-Host "📊 Iteration: $iteration | Time: $timestamp | Uptime: $($uptime.ToString('mm\:ss'))" -ForegroundColor Cyan
    Write-Host ""
    
    # Ollama Status
    $statusColor = if ($stats.OllamaHealthy) { "Green" } else { "Red" }
    Write-Host "🤖 Ollama Status: $($stats.OllamaStatus)" -ForegroundColor $statusColor
    
    # System Resources
    Write-Host "💾 Memory Usage: $($stats.MemoryUsage)%" -ForegroundColor Yellow
    Write-Host "🖥️  CPU Usage: $($stats.CPUUsage)%" -ForegroundColor Yellow
    Write-Host "🎮 GPU Usage: $($stats.GPUUsage)%" -ForegroundColor Yellow
    
    # Ollama Processes
    Write-Host "🔧 Ollama Processes: $($stats.OllamaProcesses)" -ForegroundColor Cyan
    
    # Performance Stats
    if ($stats.TotalQueries -gt 0) {
        Write-Host "📈 Total Queries: $($stats.TotalQueries)" -ForegroundColor Green
        Write-Host "⚡ Avg Response Time: $($stats.AvgResponseTime)ms" -ForegroundColor Green
        Write-Host "✅ Success Rate: $($stats.SuccessRate)%" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor Gray
    Write-Host "----------------------------------------" -ForegroundColor Gray
}

function Start-Monitoring {
    param(
        [int]$interval,
        [string]$endpoint,
        [int]$duration
    )
    
    $stats = @{
        StartTime = Get-Date
        TotalQueries = 0
        SuccessfulQueries = 0
        TotalResponseTime = 0
        AvgResponseTime = 0
        SuccessRate = 0
        OllamaHealthy = $false
        OllamaStatus = "Unknown"
        MemoryUsage = 0
        CPUUsage = 0
        GPUUsage = 0
        OllamaProcesses = 0
    }
    
    $iteration = 0
    $endTime = if ($duration -gt 0) { (Get-Date).AddMinutes($duration) } else { $null }
    
    while ($true) {
        $iteration++
        
        # Check if time limit reached
        if ($endTime -and (Get-Date) -gt $endTime) {
            Write-Host "⏰ Monitoring duration completed" -ForegroundColor Yellow
            break
        }
        
        # Update stats
        $stats.MemoryUsage = Get-MemoryUsage
        $stats.CPUUsage = Get-CPUUsage
        $stats.GPUUsage = Get-GPUUsage
        $stats.OllamaProcesses = Get-OllamaProcesses
        
        $ollamaOk, $ollamaMsg = Test-OllamaStatus -endpoint $endpoint
        $stats.OllamaHealthy = $ollamaOk
        $stats.OllamaStatus = $ollamaMsg
        
        # Calculate performance stats
        if ($stats.TotalQueries -gt 0) {
            $stats.AvgResponseTime = [Math]::Round($stats.TotalResponseTime / $stats.TotalQueries, 2)
            $stats.SuccessRate = [Math]::Round(($stats.SuccessfulQueries / $stats.TotalQueries) * 100, 2)
        }
        
        # Display stats
        Show-Header
        Show-Stats -stats $stats -iteration $iteration
        
        # Wait for next iteration
        Start-Sleep -Seconds $interval
    }
    
    # Final summary
    Write-Host ""
    Write-Host "📋 Monitoring Summary:" -ForegroundColor Green
    Write-Host "Total iterations: $iteration" -ForegroundColor Cyan
    Write-Host "Total runtime: $(((Get-Date) - $stats.StartTime).ToString('mm\:ss'))" -ForegroundColor Cyan
    Write-Host "Average memory usage: $($stats.MemoryUsage)%" -ForegroundColor Yellow
    Write-Host "Average CPU usage: $($stats.CPUUsage)%" -ForegroundColor Yellow
    Write-Host "Average GPU usage: $($stats.GPUUsage)%" -ForegroundColor Yellow
}

# Main execution
Write-Host "🚀 Starting Ollama Monitor..." -ForegroundColor Green

$healthOk, $healthMsg = Test-OllamaHealth -Endpoint $Endpoint
if (-not $healthOk) {
    Write-Host "⚠️  Warning: Ollama not responding: $healthMsg" -ForegroundColor Yellow
    Write-Host "Continuing with system monitoring only..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

try {
    Start-Monitoring -interval $Interval -endpoint $Endpoint -duration $Duration
}
catch {
    Write-Host "❌ Monitoring stopped: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "🏁 Monitoring completed" -ForegroundColor Green
} 
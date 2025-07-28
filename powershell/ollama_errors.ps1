#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ollama Error Handling System - Pure PowerShell implementation
.DESCRIPTION
    PowerShell module for comprehensive error handling and validation
#>

# Error types enum
$Script:ErrorTypes = @{
    Connection = "Connection"
    Validation = "Validation"
    Network = "Network"
    FileSystem = "FileSystem"
    API = "API"
    Unknown = "Unknown"
}

# Error statistics
$Script:ErrorStats = @{
    TotalErrors = 0
    ErrorTypes = @{}
    LastError = $null
}

function Add-Error {
    <#
    .SYNOPSIS
        Add error to statistics
    #>
    param(
        [string]$ErrorType,
        [string]$Message,
        [string]$Details = ""
    )
    
    $Script:ErrorStats.TotalErrors++
    
    if (-not $Script:ErrorStats.ErrorTypes.ContainsKey($ErrorType)) {
        $Script:ErrorStats.ErrorTypes[$ErrorType] = 0
    }
    $Script:ErrorStats.ErrorTypes[$ErrorType]++
    
    $Script:ErrorStats.LastError = @{
        Type = $ErrorType
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
}

function Get-ErrorStats {
    <#
    .SYNOPSIS
        Get error statistics
    #>
    $stats = "Total Errors: $($Script:ErrorStats.TotalErrors)"
    
    foreach ($type in $Script:ErrorStats.ErrorTypes.Keys) {
        $count = $Script:ErrorStats.ErrorTypes[$type]
        $stats += ", $type`: $count"
    }
    
    if ($Script:ErrorStats.LastError) {
        $lastError = $Script:ErrorStats.LastError
        $stats += " | Last: $($lastError.Type) - $($lastError.Message)"
    }
    
    return $stats
}

function Clear-ErrorStats {
    <#
    .SYNOPSIS
        Clear error statistics
    #>
    $Script:ErrorStats.TotalErrors = 0
    $Script:ErrorStats.ErrorTypes.Clear()
    $Script:ErrorStats.LastError = $null
}

function Test-Question {
    <#
    .SYNOPSIS
        Validate question input
    #>
    param([string]$Question)
    
    if ([string]::IsNullOrWhiteSpace($Question)) {
        Add-Error -ErrorType $Script:ErrorTypes.Validation -Message "Question cannot be empty"
        return $false
    }
    
    if ($Question.Length -gt 1000) {
        Add-Error -ErrorType $Script:ErrorTypes.Validation -Message "Question too long (max 1000 chars)"
        return $false
    }
    
    return $true
}

function Test-Model {
    <#
    .SYNOPSIS
        Validate model name
    #>
    param([string]$Model)
    
    if ([string]::IsNullOrWhiteSpace($Model)) {
        Add-Error -ErrorType $Script:ErrorTypes.Validation -Message "Model cannot be empty"
        return $false
    }
    
    if ($Model -notmatch '^[a-zA-Z0-9:_-]+$') {
        Add-Error -ErrorType $Script:ErrorTypes.Validation -Message "Invalid model name format"
        return $false
    }
    
    return $true
}

function Test-FilePath {
    <#
    .SYNOPSIS
        Validate file path
    #>
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $true
    }
    
    if (-not (Test-Path $Path)) {
        Add-Error -ErrorType $Script:ErrorTypes.FileSystem -Message "Path does not exist: $Path"
        return $false
    }
    
    return $true
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Execute command with retry mechanism
    #>
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 1
    )
    
    $attempt = 0
    $lastException = $null
    
    while ($attempt -lt $MaxRetries) {
        try {
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $lastException = $_
            $attempt++
            
            if ($attempt -lt $MaxRetries) {
                $delay = $DelaySeconds * [Math]::Pow(2, $attempt - 1)
                Start-Sleep -Seconds $delay
            }
        }
    }
    
    Add-Error -ErrorType $Script:ErrorTypes.Network -Message "Max retries exceeded" -Details $lastException.Message
    throw $lastException
}

function Test-OllamaHealth {
    <#
    .SYNOPSIS
        Check Ollama health status
    #>
    param([string]$Endpoint = "http://localhost:11434")
    
    try {
        $response = Invoke-RestMethod -Uri "$Endpoint/api/tags" -Method Get -TimeoutSec 5
        return $true, "Healthy"
    }
    catch {
        Add-Error -ErrorType $Script:ErrorTypes.Connection -Message "Ollama health check failed" -Details $_.Exception.Message
        return $false, $_.Exception.Message
    }
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Get system information
    #>
    $info = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OS = $PSVersionTable.OS
        Platform = $PSVersionTable.Platform
        Memory = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        CPU = (Get-CimInstance Win32_Processor).Name
    }
    
    return $info
}
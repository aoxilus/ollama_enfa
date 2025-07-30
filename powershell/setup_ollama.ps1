#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated Ollama Setup and Configuration
.DESCRIPTION
    Checks installations, installs dependencies, pulls models, and creates optimized configs
.PARAMETER SkipChecks
    Skip system checks (default: false)
.PARAMETER SkipModels
    Skip model downloads (default: false)
.EXAMPLE
    .\setup_ollama.ps1
    .\setup_ollama.ps1 -SkipChecks
    .\setup_ollama.ps1 -SkipModels
#>

param(
    [switch]$SkipChecks,
    [switch]$SkipModels
)

# Import error handling
. "$PSScriptRoot\ollama_errors.ps1"

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    $major = $version.Major
    $minor = $version.Minor
    
    if ($major -lt 5 -or ($major -eq 5 -and $minor -lt 1)) {
        return $false, "PowerShell 5.1 or higher required. Current: $version"
    }
    
    return $true, "PowerShell $version - OK"
}

function Test-OllamaInstallation {
    try {
        $ollamaVersion = ollama --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true, "Ollama $ollamaVersion - OK"
        } else {
            return $false, "Ollama not found or not working"
        }
    }
    catch {
        return $false, "Ollama not installed: $($_.Exception.Message)"
    }
}

function Test-PythonInstallation {
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true, "Python $pythonVersion - OK"
        } else {
            return $false, "Python not found"
        }
    }
    catch {
        return $false, "Python not installed: $($_.Exception.Message)"
    }
}

function Install-PythonDependencies {
    $requirementsFile = Join-Path $PSScriptRoot "..\python\requirements.txt"
    
    if (Test-Path $requirementsFile) {
        try {
            Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
            pip install -r $requirementsFile
            if ($LASTEXITCODE -eq 0) {
                return $true, "Python dependencies installed successfully"
            } else {
                return $false, "Failed to install Python dependencies"
            }
        }
        catch {
            return $false, "Error installing Python dependencies: $($_.Exception.Message)"
        }
    } else {
        return $false, "Requirements file not found: $requirementsFile"
    }
}

function Get-RecommendedModels {
    return @(
        "codellama:7b-code-q4_K_M",
        "llama2:7b",
        "mistral:7b"
    )
}

function Install-Models {
    param([array]$models)
    
    $results = @()
    
    foreach ($model in $models) {
        Write-Host "📥 Installing model: $model" -ForegroundColor Cyan
        
        try {
            $output = ollama pull $model 2>&1
            if ($LASTEXITCODE -eq 0) {
                $results += @{ Model = $model; Status = "Success" }
                Write-Host "✅ $model installed successfully" -ForegroundColor Green
            } else {
                $results += @{ Model = $model; Status = "Failed"; Error = $output }
                Write-Host "❌ Failed to install $model" -ForegroundColor Red
            }
        }
        catch {
            $results += @{ Model = $model; Status = "Error"; Error = $_.Exception.Message }
            Write-Host "❌ Error installing $model: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return $results
}

function Test-ModelPerformance {
    param([string]$model)
    
    Write-Host "🧪 Testing model performance: $model" -ForegroundColor Yellow
    
    $url = "http://localhost:11434/api/generate"
    $prompt = "Q: What is 2+2?`nA:"
    
    $data = @{
        model = $model
        prompt = $prompt
        stream = $false
        options = @{
            temperature = 0.1
            num_predict = 20
        }
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30
        $stopwatch.Stop()
        
        $duration = $stopwatch.ElapsedMilliseconds
        $success = $response.response -match "4"
        
        return @{
            Model = $model
            Duration = $duration
            Success = $success
            Response = $response.response
        }
    }
    catch {
        return @{
            Model = $model
            Duration = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Create-ConfigurationFiles {
    Write-Host "📝 Creating configuration files..." -ForegroundColor Yellow
    
    # Create ollama_config.env
    $configContent = @"
# Ollama Configuration
OLLAMA_ENDPOINT=http://localhost:11434
OLLAMA_MODEL=codellama:7b-code-q4_K_M

# Performance Settings
TEMPERATURE_FAST=0.1
TEMPERATURE_CODE=0.2
TEMPERATURE_GENERAL=0.7
TOKENS_FAST=20
TOKENS_NORMAL=100
TOKENS_CODE=200

# GPU Settings
GPU_ACCELERATION=true
"@
    
    $configPath = Join-Path $PSScriptRoot "..\ollama_config.env"
    $configContent | Out-File -FilePath $configPath -Encoding UTF8
    
    # Create quick_start.ps1
    $quickStartContent = @"
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick Start for Ollama
#>

Write-Host "🚀 Ollama Quick Start" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Cyan

# Test fast response
Write-Host "`n🧪 Testing fast response..." -ForegroundColor Yellow
& "$PSScriptRoot\test_fast.ps1"

# Test code generation
Write-Host "`n💻 Testing code generation..." -ForegroundColor Yellow
& "$PSScriptRoot\test_code.ps1"

Write-Host "`n✅ Quick start completed!" -ForegroundColor Green
"@
    
    $quickStartPath = Join-Path $PSScriptRoot "..\quick_start.ps1"
    $quickStartContent | Out-File -FilePath $quickStartPath -Encoding UTF8
    
    Write-Host "✅ Configuration files created" -ForegroundColor Green
    return @($configPath, $quickStartPath)
}

function Show-SetupSummary {
    param(
        [hashtable]$systemInfo,
        [array]$modelResults,
        [array]$performanceResults,
        [array]$configFiles
    )
    
    Write-Host ""
    Write-Host "📋 Setup Summary" -ForegroundColor Green
    Write-Host "================" -ForegroundColor Cyan
    
    Write-Host "`n🖥️  System Information:" -ForegroundColor Yellow
    foreach ($key in $systemInfo.Keys) {
        Write-Host "  $key`: $($systemInfo[$key])" -ForegroundColor White
    }
    
    Write-Host "`n📦 Model Installation:" -ForegroundColor Yellow
    foreach ($result in $modelResults) {
        $color = if ($result.Status -eq "Success") { "Green" } else { "Red" }
        Write-Host "  $($result.Model): $($result.Status)" -ForegroundColor $color
    }
    
    Write-Host "`n⚡ Performance Test Results:" -ForegroundColor Yellow
    foreach ($result in $performanceResults) {
        if ($result.Success) {
            Write-Host "  $($result.Model): $($result.Duration)ms ✅" -ForegroundColor Green
        } else {
            Write-Host "  $($result.Model): Failed ❌" -ForegroundColor Red
        }
    }
    
    Write-Host "`n📁 Configuration Files:" -ForegroundColor Yellow
    foreach ($file in $configFiles) {
        Write-Host "  $file" -ForegroundColor White
    }
    
    Write-Host "`n🎉 Setup completed successfully!" -ForegroundColor Green
    Write-Host "Run '.\quick_start.ps1' to test your installation" -ForegroundColor Cyan
}

# Main execution
Write-Host "🚀 Starting Ollama Setup..." -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Cyan

$systemInfo = @{}
$modelResults = @()
$performanceResults = @()
$configFiles = @()

# System checks
if (-not $SkipChecks) {
    Write-Host "`n🔍 System Checks..." -ForegroundColor Yellow
    
    $psOk, $psMsg = Test-PowerShellVersion
    $systemInfo["PowerShell"] = $psMsg
    if (-not $psOk) {
        Write-Host "❌ $psMsg" -ForegroundColor Red
        exit 1
    }
    
    $ollamaOk, $ollamaMsg = Test-OllamaInstallation
    $systemInfo["Ollama"] = $ollamaMsg
    if (-not $ollamaOk) {
        Write-Host "❌ $ollamaMsg" -ForegroundColor Red
        Write-Host "Please install Ollama from https://ollama.ai" -ForegroundColor Yellow
        exit 1
    }
    
    $pythonOk, $pythonMsg = Test-PythonInstallation
    $systemInfo["Python"] = $pythonMsg
    
    Write-Host "✅ System checks completed" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipping system checks" -ForegroundColor Yellow
}

# Install Python dependencies
if ($pythonOk) {
    $depOk, $depMsg = Install-PythonDependencies
    $systemInfo["Python Dependencies"] = $depMsg
} else {
    $systemInfo["Python Dependencies"] = "Skipped (Python not available)"
}

# Install models
if (-not $SkipModels) {
    Write-Host "`n📥 Installing Models..." -ForegroundColor Yellow
    $models = Get-RecommendedModels
    $modelResults = Install-Models -models $models
} else {
    Write-Host "⏭️  Skipping model installation" -ForegroundColor Yellow
}

# Test performance
if ($modelResults.Count -gt 0) {
    Write-Host "`n⚡ Testing Model Performance..." -ForegroundColor Yellow
    
    foreach ($result in $modelResults) {
        if ($result.Status -eq "Success") {
            $perfResult = Test-ModelPerformance -model $result.Model
            $performanceResults += $perfResult
        }
    }
}

# Create configuration files
$configFiles = Create-ConfigurationFiles

# Show summary
Show-SetupSummary -systemInfo $systemInfo -modelResults $modelResults -performanceResults $performanceResults -configFiles $configFiles 
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated Ollama Performance Optimization
.DESCRIPTION
    Discovers available models, tests configurations, selects best performing model
.PARAMETER Endpoint
    Ollama endpoint (default: http://localhost:11434)
.PARAMETER OutputFile
    Output file for optimization report (default: ollama_optimization_report.txt)
.EXAMPLE
    .\optimize_ollama.ps1
    .\optimize_ollama.ps1 "http://localhost:11434" "my_report.txt"
#>

param(
    [string]$Endpoint = "http://localhost:11434",
    [string]$OutputFile = "ollama_optimization_report.txt"
)

# Import error handling
. "$PSScriptRoot\ollama_errors.ps1"

class OllamaOptimizer {
    [string]$Endpoint
    [string]$OutputFile
    [hashtable]$Results
    [hashtable]$BestConfig
    
    OllamaOptimizer([string]$endpoint, [string]$outputFile) {
        $this.Endpoint = $endpoint
        $this.OutputFile = $outputFile
        $this.Results = @{}
        $this.BestConfig = @{}
    }
    
    [array] GetAvailableModels() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.Endpoint)/api/tags" -Method Get -TimeoutSec 10
            $models = @()
            
            foreach ($model in $response.models) {
                $models += $model.name
            }
            
            return $models
        }
        catch {
            Add-Error -ErrorType "API" -Message "Failed to get models" -Details $_.Exception.Message
            return @()
        }
    }
    
    [hashtable] TestModel([string]$model, [hashtable]$config) {
        $testCases = @(
            @{ question = "What is 2+2?"; expected = "4" },
            @{ question = "What is 3+3?"; expected = "6" },
            @{ question = "What is 5+5?"; expected = "10" }
        )
        
        $tests = @()
        $totalTime = 0
        $successCount = 0
        
        foreach ($testCase in $testCases) {
            $testResult = $this.RunSingleTest($model, $config, $testCase.question, $testCase.expected)
            $tests += $testResult
            
            if ($testResult.Success) {
                $successCount++
                $totalTime += $testResult.Duration
            }
        }
        
        $successRate = [Math]::Round(($successCount / $testCases.Count) * 100, 2)
        $avgTime = if ($successCount -gt 0) { [Math]::Round($totalTime / $successCount, 2) } else { 0 }
        
        return @{
            Model = $model
            Config = $config
            Tests = $tests
            AvgTime = $avgTime
            SuccessRate = $successRate
            TotalTests = $testCases.Count
        }
    }
    
    [hashtable] RunSingleTest([string]$model, [hashtable]$config, [string]$question, [string]$expected) {
        $url = "$($this.Endpoint)/api/generate"
        $prompt = "Q: $question`nA:"
        
        $data = @{
            model = $model
            prompt = $prompt
            stream = $false
            options = $config
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30
            
            $stopwatch.Stop()
            $duration = $stopwatch.ElapsedMilliseconds
            
            $success = $response.response -match $expected
            
            return @{
                Question = $question
                Expected = $expected
                Response = $response.response
                Duration = $duration
                Success = $success
            }
        }
        catch {
            $stopwatch.Stop()
            return @{
                Question = $question
                Expected = $expected
                Response = "ERROR"
                Duration = $stopwatch.ElapsedMilliseconds
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    [void] Optimize() {
        Write-Host "🚀 Starting Ollama Optimization..." -ForegroundColor Green
        Write-Host "Endpoint: $($this.Endpoint)" -ForegroundColor Cyan
        Write-Host ""
        
        # Get available models
        Write-Host "📋 Discovering available models..." -ForegroundColor Yellow
        $models = $this.GetAvailableModels()
        
        if ($models.Count -eq 0) {
            Write-Host "❌ No models found" -ForegroundColor Red
            return
        }
        
        Write-Host "Found $($models.Count) models: $($models -join ', ')" -ForegroundColor Green
        Write-Host ""
        
        # Test configurations
        $configs = @(
            @{ temperature = 0.1; num_predict = 20; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 },
            @{ temperature = 0.2; num_predict = 50; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 },
            @{ temperature = 0.3; num_predict = 100; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 }
        )
        
        $bestScore = 0
        $bestResult = $null
        
        foreach ($model in $models) {
            Write-Host "🧪 Testing model: $model" -ForegroundColor Cyan
            
            foreach ($config in $configs) {
                Write-Host "  Config: temp=$($config.temperature), tokens=$($config.num_predict)" -ForegroundColor Yellow
                
                $result = $this.TestModel($model, $config)
                $this.Results["$model-$($config.temperature)-$($config.num_predict)"] = $result
                
                # Calculate score (success rate * speed factor)
                $speedFactor = if ($result.AvgTime -gt 0) { 1000 / $result.AvgTime } else { 0 }
                $score = $result.SuccessRate * $speedFactor
                
                if ($score -gt $bestScore) {
                    $bestScore = $score
                    $bestResult = $result
                    $this.BestConfig = @{
                        Model = $model
                        Config = $config
                        Score = $score
                    }
                }
                
                Write-Host "    Success: $($result.SuccessRate)%, Avg Time: $($result.AvgTime)ms" -ForegroundColor Green
            }
        }
        
        # Generate report
        $this.GenerateReport()
        
        Write-Host ""
        Write-Host "🏆 Best Configuration:" -ForegroundColor Green
        Write-Host "Model: $($this.BestConfig.Model)" -ForegroundColor Cyan
        Write-Host "Temperature: $($this.BestConfig.Config.temperature)" -ForegroundColor Yellow
        Write-Host "Tokens: $($this.BestConfig.Config.num_predict)" -ForegroundColor Yellow
        Write-Host "Score: $([Math]::Round($this.BestConfig.Score, 2))" -ForegroundColor Green
    }
    
    [void] GenerateReport() {
        $report = @"
# Ollama Optimization Report
Generated: $(Get-Date)

## Best Configuration
- Model: $($this.BestConfig.Model)
- Temperature: $($this.BestConfig.Config.temperature)
- Num Predict: $($this.BestConfig.Config.num_predict)
- Top K: $($this.BestConfig.Config.top_k)
- Top P: $($this.BestConfig.Config.top_p)
- Repeat Penalty: $($this.BestConfig.Config.repeat_penalty)
- Score: $([Math]::Round($this.BestConfig.Score, 2))

## All Results
"@
        
        foreach ($key in $this.Results.Keys) {
            $result = $this.Results[$key]
            $report += "`n### $($result.Model) (temp=$($result.Config.temperature), tokens=$($result.Config.num_predict))`n"
            $report += "- Success Rate: $($result.SuccessRate)%`n"
            $report += "- Average Time: $($result.AvgTime)ms`n"
            $report += "- Tests: $($result.TotalTests)`n"
        }
        
        $report | Out-File -FilePath $this.OutputFile -Encoding UTF8
        Write-Host "📄 Report saved to: $($this.OutputFile)" -ForegroundColor Green
    }
}

# Main execution
$healthOk, $healthMsg = Test-OllamaHealth -Endpoint $Endpoint
if (-not $healthOk) {
    Write-Host "❌ Ollama not available: $healthMsg" -ForegroundColor Red
    exit 1
}

$optimizer = [OllamaOptimizer]::new($Endpoint, $OutputFile)
$optimizer.Optimize() 
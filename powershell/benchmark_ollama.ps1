#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive Ollama Benchmarking
.DESCRIPTION
    Compares performance of different Ollama models across various test cases
.PARAMETER Models
    Comma-separated list of models to benchmark (default: codellama:7b-code-q4_K_M,llama2:7b)
.PARAMETER Endpoint
    Ollama endpoint (default: http://localhost:11434)
.PARAMETER OutputFile
    Output file for benchmark report (default: ollama_benchmark_report.txt)
.EXAMPLE
    .\benchmark_ollama.ps1
    .\benchmark_ollama.ps1 "codellama:7b-code-q4_K_M,llama2:7b,mistral:7b"
    .\benchmark_ollama.ps1 "codellama:7b-code-q4_K_M" "http://localhost:11434" "my_benchmark.txt"
#>

param(
    [string]$Models = "codellama:7b-code-q4_K_M,llama2:7b",
    [string]$Endpoint = "http://localhost:11434",
    [string]$OutputFile = "ollama_benchmark_report.txt"
)

# Import error handling
. "$PSScriptRoot\ollama_errors.ps1"

class OllamaBenchmark {
    [string]$Endpoint
    [string]$OutputFile
    [array]$Models
    [hashtable]$Results
    [hashtable]$Stats
    
    OllamaBenchmark([string]$endpoint, [string]$outputFile, [array]$models) {
        $this.Endpoint = $endpoint
        $this.OutputFile = $outputFile
        $this.Models = $models
        $this.Results = @{}
        $this.Stats = @{}
    }
    
    [array] GetTestCases() {
        return @(
            @{ 
                Name = "Simple Math"
                Question = "What is 2+2?"
                Expected = "4"
                Category = "Math"
            },
            @{ 
                Name = "Medium Math"
                Question = "What is 15+27?"
                Expected = "42"
                Category = "Math"
            },
            @{ 
                Name = "Simple Code"
                Question = "Write a Python function to add two numbers"
                Expected = "def"
                Category = "Code"
            },
            @{ 
                Name = "General Knowledge"
                Question = "What is the capital of France?"
                Expected = "Paris"
                Category = "General"
            },
            @{ 
                Name = "Logic"
                Question = "If A=1 and B=2, what is A+B?"
                Expected = "3"
                Category = "Logic"
            }
        )
    }
    
    [array] GetConfigurations() {
        return @(
            @{ Name = "Fast"; temperature = 0.1; num_predict = 20; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 },
            @{ Name = "Balanced"; temperature = 0.3; num_predict = 100; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 },
            @{ Name = "Quality"; temperature = 0.5; num_predict = 200; top_k = 10; top_p = 0.9; repeat_penalty = 1.1 }
        )
    }
    
    [hashtable] RunBenchmark([string]$model, [hashtable]$config, [hashtable]$testCase) {
        $url = "$($this.Endpoint)/api/generate"
        
        # Adjust prompt based on category
        switch ($testCase.Category) {
            "Math" { $prompt = "Q: $($testCase.Question)`nA:" }
            "Code" { $prompt = "Write code for: $($testCase.Question)`n`n```python`n" }
            default { $prompt = "Q: $($testCase.Question)`nA:" }
        }
        
        $data = @{
            model = $model
            prompt = $prompt
            stream = $false
            options = @{
                temperature = $config.temperature
                num_predict = $config.num_predict
                top_k = $config.top_k
                top_p = $config.top_p
                repeat_penalty = $config.repeat_penalty
            }
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $response = Invoke-RestMethod -Uri $url -Method Post -Body ($data | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 60
            
            $stopwatch.Stop()
            $duration = $stopwatch.ElapsedMilliseconds
            
            $success = $response.response -match $testCase.Expected
            
            return @{
                Model = $model
                Config = $config.Name
                TestCase = $testCase.Name
                Category = $testCase.Category
                Question = $testCase.Question
                Expected = $testCase.Expected
                Response = $response.response
                Duration = $duration
                Success = $success
                Timestamp = Get-Date
            }
        }
        catch {
            $stopwatch.Stop()
            return @{
                Model = $model
                Config = $config.Name
                TestCase = $testCase.Name
                Category = $testCase.Category
                Question = $testCase.Question
                Expected = $testCase.Expected
                Response = "ERROR"
                Duration = $stopwatch.ElapsedMilliseconds
                Success = $false
                Error = $_.Exception.Message
                Timestamp = Get-Date
            }
        }
    }
    
    [void] RunBenchmarks() {
        Write-Host "🏁 Starting Ollama Benchmark..." -ForegroundColor Green
        Write-Host "Endpoint: $($this.Endpoint)" -ForegroundColor Cyan
        Write-Host "Models: $($this.Models -join ', ')" -ForegroundColor Cyan
        Write-Host ""
        
        $testCases = $this.GetTestCases()
        $configs = $this.GetConfigurations()
        
        $totalTests = $this.Models.Count * $configs.Count * $testCases.Count
        $currentTest = 0
        
        foreach ($model in $this.Models) {
            Write-Host "🧪 Testing model: $model" -ForegroundColor Cyan
            
            foreach ($config in $configs) {
                Write-Host "  Config: $($config.Name)" -ForegroundColor Yellow
                
                foreach ($testCase in $testCases) {
                    $currentTest++
                    $progress = [Math]::Round(($currentTest / $totalTests) * 100, 1)
                    Write-Host "    [$progress%] $($testCase.Name)..." -ForegroundColor Gray -NoNewline
                    
                    $result = $this.RunBenchmark($model, $config, $testCase)
                    $key = "$model-$($config.Name)-$($testCase.Name)"
                    $this.Results[$key] = $result
                    
                    if ($result.Success) {
                        Write-Host " ✅" -ForegroundColor Green
                    } else {
                        Write-Host " ❌" -ForegroundColor Red
                    }
                }
            }
        }
        
        $this.CalculateStats()
        $this.GenerateReport()
    }
    
    [void] CalculateStats() {
        Write-Host ""
        Write-Host "📊 Calculating statistics..." -ForegroundColor Yellow
        
        foreach ($model in $this.Models) {
            $this.Stats[$model] = @{
                TotalTests = 0
                SuccessfulTests = 0
                TotalTime = 0
                AvgTime = 0
                SuccessRate = 0
                ByCategory = @{}
                ByConfig = @{}
            }
            
            foreach ($key in $this.Results.Keys) {
                if ($key -match "^$model-") {
                    $result = $this.Results[$key]
                    $stats = $this.Stats[$model]
                    
                    $stats.TotalTests++
                    $stats.TotalTime += $result.Duration
                    
                    if ($result.Success) {
                        $stats.SuccessfulTests++
                    }
                    
                    # By category
                    if (-not $stats.ByCategory.ContainsKey($result.Category)) {
                        $stats.ByCategory[$result.Category] = @{ Total = 0; Success = 0; Time = 0 }
                    }
                    $stats.ByCategory[$result.Category].Total++
                    $stats.ByCategory[$result.Category].Time += $result.Duration
                    if ($result.Success) {
                        $stats.ByCategory[$result.Category].Success++
                    }
                    
                    # By config
                    if (-not $stats.ByConfig.ContainsKey($result.Config)) {
                        $stats.ByConfig[$result.Config] = @{ Total = 0; Success = 0; Time = 0 }
                    }
                    $stats.ByConfig[$result.Config].Total++
                    $stats.ByConfig[$result.Config].Time += $result.Duration
                    if ($result.Success) {
                        $stats.ByConfig[$result.Config].Success++
                    }
                }
            }
            
            # Calculate averages
            $stats.SuccessRate = if ($stats.TotalTests -gt 0) { [Math]::Round(($stats.SuccessfulTests / $stats.TotalTests) * 100, 2) } else { 0 }
            $stats.AvgTime = if ($stats.TotalTests -gt 0) { [Math]::Round($stats.TotalTime / $stats.TotalTests, 2) } else { 0 }
        }
    }
    
    [void] GenerateReport() {
        $report = @"
# Ollama Benchmark Report
Generated: $(Get-Date)

## Summary
- Models tested: $($this.Models.Count)
- Total test cases: $($this.GetTestCases().Count)
- Total configurations: $($this.GetConfigurations().Count)
- Total tests run: $($this.Results.Count)

## Model Performance Summary
"@
        
        foreach ($model in $this.Models) {
            $stats = $this.Stats[$model]
            $report += "`n### $model`n"
            $report += "- Success Rate: $($stats.SuccessRate)%`n"
            $report += "- Average Time: $($stats.AvgTime)ms`n"
            $report += "- Total Tests: $($stats.TotalTests)`n"
            $report += "- Successful: $($stats.SuccessfulTests)`n"
        }
        
        $report += "`n## Detailed Results`n"
        
        foreach ($key in $this.Results.Keys | Sort-Object) {
            $result = $this.Results[$key]
            $status = if ($result.Success) { "✅" } else { "❌" }
            $report += "`n### $key $status`n"
            $report += "- Duration: $($result.Duration)ms`n"
            $report += "- Success: $($result.Success)`n"
            $report += "- Response: $($result.Response)`n"
        }
        
        $report | Out-File -FilePath $this.OutputFile -Encoding UTF8
        Write-Host "📄 Report saved to: $($this.OutputFile)" -ForegroundColor Green
        
        # Display summary
        Write-Host ""
        Write-Host "🏆 Benchmark Summary:" -ForegroundColor Green
        foreach ($model in $this.Models) {
            $stats = $this.Stats[$model]
            Write-Host "$model: $($stats.SuccessRate)% success, $($stats.AvgTime)ms avg" -ForegroundColor Cyan
        }
    }
}

# Main execution
$healthOk, $healthMsg = Test-OllamaHealth -Endpoint $Endpoint
if (-not $healthOk) {
    Write-Host "❌ Ollama not available: $healthMsg" -ForegroundColor Red
    exit 1
}

$modelList = $Models -split ","
$benchmark = [OllamaBenchmark]::new($Endpoint, $OutputFile, $modelList)
$benchmark.RunBenchmarks() 
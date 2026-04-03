$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo
$bin = Join-Path $repo ".butler\bin\llama-server.exe"
$modelsDir = Join-Path $repo ".butler\models"
$gguf = Get-ChildItem $modelsDir -Filter "*.gguf" | Select-Object -First 1
if (-not $gguf) { Write-Error "No GGUF in .butler/models"; exit 1 }
$logDir = Join-Path $repo ".butler\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$outLog = Join-Path $logDir "run.out"
$errLog = Join-Path $logDir "run.err"
$arg = "--host 127.0.0.1 --port 8080 --model `"$($gguf.FullName)`" --ctx-size 4096"
$p = Start-Process -FilePath $bin -ArgumentList $arg -PassThru -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog
$p.Id

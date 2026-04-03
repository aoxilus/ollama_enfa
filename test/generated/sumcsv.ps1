param(
    [string]$inputFile,
    [string]$columnName
)

if (-not (Test-Path -LiteralPath $inputFile)) { exit 1 }

$headerLine = (Get-Content -LiteralPath $inputFile -First 1)
$headers = $headerLine -split ',' | ForEach-Object { $_.Trim() }
if ($headers -notcontains $columnName) { exit 1 }

$sum = (Import-Csv -LiteralPath $inputFile | Measure-Object -Property $columnName -Sum).Sum
$sumInt = [math]::Floor([double]$sum)
if ([double]$sum -eq $sumInt) { Write-Output ([int]$sumInt) } else { Write-Output $sum }
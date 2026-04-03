param (
    [string]$inputJsonPath
)

if (-not (Test-Path -Path $inputJsonPath)) {
    Write-Output "File not found: $inputJsonPath"
    exit 1
}

try {
    $json = Get-Content -Path $inputJsonPath -Raw | ConvertFrom-Json
    if (-not $json -or -not $json.name -or -not $json.age) {
        Write-Output "Invalid JSON format"
        exit 1
    }
    Write-Output "name=$($json.name) age=$($json.age)"
} catch {
    Write-Output "Error parsing JSON: $_"
    exit 1
}
for ($i = 0; $i -lt 90; $i++) {
    try {
        $null = Invoke-RestMethod -Uri "http://127.0.0.1:8080/v1/models" -TimeoutSec 5
        Write-Output "READY"
        exit 0
    } catch {
        Start-Sleep -Seconds 1
    }
}
Write-Output "TIMEOUT"
exit 1

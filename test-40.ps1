while ($true) {
    try {
        $response = Invoke-WebRequest -Uri "http://10.5.19.40/admin/config.php" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "$(Get-Date) - SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "$(Get-Date) - Not reachable: $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Seconds 15
}
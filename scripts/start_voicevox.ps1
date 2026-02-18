$enginePath = "C:\Program Files\voicevox_engine-windows-cpu-0.25.1.7z\windows-cpu\run.exe"
$healthUrl = "http://localhost:50021/docs"
$maxWaitSeconds = 15

if (-not (Test-Path $enginePath)) {
  Write-Host "VOICEVOX engine not found: $enginePath" -ForegroundColor Red
  exit 1
}

Write-Host "Starting VOICEVOX Engine..." -ForegroundColor Cyan
Start-Process -FilePath $enginePath -ArgumentList "--host","0.0.0.0","--port","50021"

Write-Host "Checking server status..." -ForegroundColor Cyan
$start = Get-Date
while ($true) {
  try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 2
    if ($response.StatusCode -eq 200) {
      Write-Host "VOICEVOX is running at $healthUrl" -ForegroundColor Green
      break
    }
  } catch {
    # keep waiting
  }

  if (((Get-Date) - $start).TotalSeconds -ge $maxWaitSeconds) {
    Write-Host "VOICEVOX not responding yet. Check firewall and network." -ForegroundColor Yellow
    break
  }
  Start-Sleep -Seconds 1
}

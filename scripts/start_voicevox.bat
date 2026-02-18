@echo off
set ENGINE_PATH=C:\Program Files\voicevox_engine-windows-cpu-0.25.1.7z\windows-cpu\run.exe
set HEALTH_URL=http://localhost:50021/docs

if not exist "%ENGINE_PATH%" (
  echo VOICEVOX engine not found: %ENGINE_PATH%
  exit /b 1
)

echo Starting VOICEVOX Engine...
start "VOICEVOX Engine" "%ENGINE_PATH%" --host 0.0.0.0 --port 50021

echo Checking server status...
powershell -NoProfile -Command "for ($i=0; $i -lt 15; $i++) { try { $r = Invoke-WebRequest -Uri '%HEALTH_URL%' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { Write-Host 'VOICEVOX is running at %HEALTH_URL%'; exit 0 } } catch {} Start-Sleep -Seconds 1 } Write-Host 'VOICEVOX not responding yet. Check firewall and network.'"

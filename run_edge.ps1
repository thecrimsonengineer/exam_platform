$ErrorActionPreference = "Stop"

$port = 8080
$url = "http://localhost:$port"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CSP11 Exam Platform - Edge Development" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting Flutter Web Server on $url ..."
Write-Host ""

$flutter = Start-Process powershell `
    -ArgumentList "-NoExit", "-Command", "flutter run -d web-server --web-port $port" `
    -PassThru

Write-Host "Waiting for Flutter Web Server..." -ForegroundColor Yellow

$ready = $false

for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 1

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 2

        if ($response.StatusCode -ge 200) {
            $ready = $true
            break
        }
    }
    catch {
        # Server is not ready yet
    }
}

if (-not $ready) {
    Write-Host ""
    Write-Host "Flutter Web Server did not become ready." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Flutter Web Server is ready." -ForegroundColor Green
Write-Host "Opening Microsoft Edge..." -ForegroundColor Green
Write-Host ""

$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

$edge = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edge) {
    Write-Host "Microsoft Edge executable was not found." -ForegroundColor Red
    exit 1
}

Start-Process $edge $url

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CSP11 is running at:" -ForegroundColor Cyan
Write-Host " $url" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
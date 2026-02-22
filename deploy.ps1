# deploy.ps1 — szybki upload kodu na serwer LEM
# Użycie: .\deploy.ps1
# Opcjonalnie: .\deploy.ps1 -Message "opis zmian"

param(
    [string]$Message = "",
    [string]$Server = "kochnik@100.122.147.29",
    [string]$RemotePath = "/home/kochnik/LEM"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== LEM Deploy ===" -ForegroundColor Cyan

# 1. Commit i push lokalnie (LEM V1)
Set-Location "$PSScriptRoot\LEM V1"

$status = git status --porcelain
if ($status) {
    if (-not $Message) {
        $Message = "deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    Write-Host "[1/4] Commit: $Message" -ForegroundColor Yellow
    git add -A
    git commit -m $Message
} else {
    Write-Host "[1/4] Brak zmian do commita" -ForegroundColor Green
}

Write-Host "[2/4] Push na GitHub..." -ForegroundColor Yellow
git push origin master
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: git push nie powiodl sie!" -ForegroundColor Red
    exit 1
}
Write-Host "Push OK" -ForegroundColor Green

# 2. Pull na serwerze + restart serwisu
Write-Host "[3/4] Pull na serwerze..." -ForegroundColor Yellow
ssh $Server "cd $RemotePath && git fetch origin master && git reset --hard origin/master"
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: git pull na serwerze nie powiodl sie!" -ForegroundColor Red
    exit 1
}
Write-Host "Pull OK" -ForegroundColor Green

Write-Host "[4/4] Restart serwisu..." -ForegroundColor Yellow
ssh $Server "cd $RemotePath && source venv/bin/activate && pip install -q -r requirements.txt && sudo systemctl restart lem-api"
if ($LASTEXITCODE -ne 0) {
    Write-Host "UWAGA: Restart moze wymagac sudo z haslem — uruchom recznie: sudo systemctl restart lem-api" -ForegroundColor Yellow
}

# 3. Health check
Start-Sleep -Seconds 3
Write-Host "`nHealth check..." -ForegroundColor Cyan
ssh $Server "curl -sS http://127.0.0.1:8000/health"

Write-Host "`n=== Deploy zakonczony ===" -ForegroundColor Green
Write-Host "API: http://100.122.147.29:8000" -ForegroundColor Cyan
Write-Host ""

# deploy.ps1 — szybki upload kodu LEM na serwer
# Synchronizuje backend (LEM V1) i frontend (Lovable/managerial-compass)
#
# Użycie:
#   .\deploy.ps1                           # deploy backendu + frontendu
#   .\deploy.ps1 -Message "opis zmian"     # z opisem commita
#   .\deploy.ps1 -BackendOnly              # tylko backend
#   .\deploy.ps1 -FrontendOnly             # tylko frontend

param(
    [string]$Message = "",
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [string]$Server = "kochnik@100.122.147.29",
    [string]$RemotePath = "/home/kochnik/LEM"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "`n=== LEM Deploy ===" -ForegroundColor Cyan
Write-Host "Serwer: $Server" -ForegroundColor DarkGray

# ---------- FRONTEND (Lovable) ----------
if (-not $BackendOnly) {
    Write-Host "`n--- Frontend (Lovable) ---" -ForegroundColor Magenta

    Set-Location "$root\frontend"

    # Pobierz najnowsze zmiany z Lovable (GitHub)
    Write-Host "[F1] Pull zmian z Lovable..." -ForegroundColor Yellow
    git pull origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: git pull frontend nie powiodl sie!" -ForegroundColor Red
        exit 1
    }

    # Build produkcyjny
    Write-Host "[F2] Build frontendu..." -ForegroundColor Yellow
    npm ci --silent 2>$null
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: npm run build nie powiodl sie!" -ForegroundColor Red
        exit 1
    }

    # Upload dist/ na serwer
    Write-Host "[F3] Upload dist/ na serwer..." -ForegroundColor Yellow
    scp -r "$root\frontend\dist" "${Server}:${RemotePath}/frontend_dist_new"
    ssh $Server "cd $RemotePath && rm -rf frontend/dist && mv frontend_dist_new frontend/dist"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: upload frontendu nie powiodl sie!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Frontend OK" -ForegroundColor Green
}

# ---------- BACKEND (LEM V1) ----------
if (-not $FrontendOnly) {
    Write-Host "`n--- Backend (LEM V1) ---" -ForegroundColor Magenta

    Set-Location "$root\LEM V1"

    # Commit jeśli są zmiany
    $status = git status --porcelain
    if ($status) {
        if (-not $Message) {
            $Message = "deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        Write-Host "[B1] Commit: $Message" -ForegroundColor Yellow
        git add -A
        git commit -m $Message
    } else {
        Write-Host "[B1] Brak zmian do commita" -ForegroundColor Green
    }

    # Push na GitHub
    Write-Host "[B2] Push na GitHub..." -ForegroundColor Yellow
    git push origin master
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: git push nie powiodl sie!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Push OK" -ForegroundColor Green

    # Pull na serwerze + restart
    Write-Host "[B3] Pull na serwerze..." -ForegroundColor Yellow
    ssh $Server "cd $RemotePath && git fetch origin master && git reset --hard origin/master"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: git pull na serwerze nie powiodl sie!" -ForegroundColor Red
        exit 1
    }

    Write-Host "[B4] Instalacja zaleznosci + restart..." -ForegroundColor Yellow
    ssh $Server "cd $RemotePath && source venv/bin/activate && pip install -q -r requirements.txt && sudo systemctl restart lem-api"
}

# ---------- HEALTH CHECK ----------
Write-Host "`nHealth check..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
ssh $Server "curl -sS http://127.0.0.1:8010/health"

Write-Host "`n=== Deploy zakonczony ===" -ForegroundColor Green
Write-Host "API:      http://100.122.147.29:8010" -ForegroundColor Cyan
Write-Host "Frontend: http://100.122.147.29:8010" -ForegroundColor Cyan
Write-Host ""

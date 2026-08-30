# Compilador PowerShell puro - MuArrawn
# Rode como Admin no Windows

Write-Host "=== COMPILADOR MuArrawn ===" -ForegroundColor Magenta

# Instala ps2exe se não tiver
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Instalando modulo ps2exe..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module ps2exe -Force -Scope CurrentUser -SkipPublisherCheck
}
Import-Module ps2exe

$inputFile = ".\MuArrawn-Complete.ps1"
$iconFile = ".\MuArrawn-icon.ico"
$outputFile = ".\MuArrawn.exe"

if (-not (Test-Path $inputFile)) { Write-Host "Arquivo $inputFile nao encontrado! Coloque na mesma pasta." -ForegroundColor Red; exit }
if (-not (Test-Path $iconFile)) { Write-Host "Icone nao encontrado, compilando sem icone..." -ForegroundColor Yellow; $iconFile = $null }

Write-Host "Compilando $outputFile ..." -ForegroundColor Cyan

$params = @{
    inputFile = $inputFile
    outputFile = $outputFile
    title = "MuArrawn Optimizer"
    description = "MuArrawn - Debloat, Otimizacao e DNS Flush Tool"
    company = "MuArrawn"
    product = "MuArrawn Tool"
    version = "2.0.0.0"
    noConsole = $true
    requireAdmin = $true
    x64 = $true
    STA = $true
}

if ($iconFile) { $params.iconFile = $iconFile }

Invoke-ps2exe @params

Write-Host "SUCESSO! MuArrawn.exe criado!" -ForegroundColor Green
Write-Host "Local: $((Get-Location).Path)\$outputFile" -ForegroundColor White
Start-Sleep 3

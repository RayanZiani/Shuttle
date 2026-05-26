# Lance l'analyse SonarCloud (depuis le dossier Shuttle)
# Token : variable SONAR_TOKEN ou fichier ../.sonar-token (non versionné)

$ErrorActionPreference = "Stop"

$tokenFile = Join-Path $PSScriptRoot "..\.sonar-token"
if (-not $env:SONAR_TOKEN -and (Test-Path $tokenFile)) {
    $env:SONAR_TOKEN = (Get-Content $tokenFile -Raw).Trim()
}

if (-not $env:SONAR_TOKEN) {
    Write-Host "ERREUR : token SonarCloud manquant." -ForegroundColor Red
    Write-Host "  1. https://sonarcloud.io/account/security -> Generate Token" -ForegroundColor Yellow
    Write-Host '  2. $env:SONAR_TOKEN = "..."  OU  coller le token dans .sonar-token' -ForegroundColor Yellow
    exit 1
}

$propsFile = Join-Path $PSScriptRoot "sonar-project.properties"
if (-not (Test-Path $propsFile)) {
    Write-Host "ERREUR : sonar-project.properties introuvable" -ForegroundColor Red
    exit 1
}

$org = (Select-String -Path $propsFile -Pattern '^sonar\.organization=(.+)$').Matches.Groups[1].Value.Trim()
$key = (Select-String -Path $propsFile -Pattern '^sonar\.projectKey=(.+)$').Matches.Groups[1].Value.Trim()

if ($org -match '^<' -or $key -match '^<') {
    Write-Host "ERREUR : complétez sonar.organization et sonar.projectKey dans sonar-project.properties" -ForegroundColor Red
    exit 1
}

$scanner = Get-Command sonar-scanner -ErrorAction SilentlyContinue
if ($scanner) {
    $scannerPath = $scanner.Source
} else {
    $scannerPath = Join-Path $PSScriptRoot "..\tools\sonar-scanner-6.2.1.4610-windows-x64\bin\sonar-scanner.bat"
    if (-not (Test-Path $scannerPath)) {
        Write-Host "ERREUR : sonar-scanner introuvable (tools/ ou PATH)" -ForegroundColor Red
        exit 1
    }
}

# PowerShell interprète mal -Dsonar.xxx sans guillemets
$args = @(
    "-Dsonar.organization=$org",
    "-Dsonar.projectKey=$key",
    "-Dsonar.host.url=https://sonarcloud.io",
    "-Dsonar.token=$($env:SONAR_TOKEN)"
)

Write-Host "Analyse SonarCloud : org=$org project=$key" -ForegroundColor Cyan
Push-Location $PSScriptRoot
try {
    & $scannerPath @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

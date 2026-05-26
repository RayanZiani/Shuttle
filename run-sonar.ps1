# Lance l'analyse SonarCloud (depuis le dossier Shuttle)
# Prérequis : sonar-scanner dans le PATH, variable SONAR_TOKEN définie

$ErrorActionPreference = "Stop"

if (-not $env:SONAR_TOKEN) {
    Write-Host "ERREUR : définissez votre token SonarCloud :" -ForegroundColor Red
    Write-Host '  $env:SONAR_TOKEN = "votre_token"' -ForegroundColor Yellow
    exit 1
}

$propsFile = Join-Path $PSScriptRoot "sonar-project.properties"
if (-not (Test-Path $propsFile)) {
    Write-Host "ERREUR : sonar-project.properties introuvable" -ForegroundColor Red
    exit 1
}

$org = (Select-String -Path $propsFile -Pattern '^sonar\.organization=(.+)$').Matches.Groups[1].Value
$key = (Select-String -Path $propsFile -Pattern '^sonar\.projectKey=(.+)$').Matches.Groups[1].Value

if ($org -match '^<' -or $key -match '^<') {
    Write-Host "ERREUR : complétez sonar.organization et sonar.projectKey dans sonar-project.properties" -ForegroundColor Red
    exit 1
}

$scanner = Get-Command sonar-scanner -ErrorAction SilentlyContinue
if (-not $scanner) {
    $localScanner = Join-Path $PSScriptRoot "..\tools\sonar-scanner-6.2.1.4610-windows-x64\bin\sonar-scanner.bat"
    if (Test-Path $localScanner) {
        $scanner = $localScanner
    } else {
        Write-Host "ERREUR : installez sonar-scanner ou placez-le dans tools/" -ForegroundColor Red
        exit 1
    }
} else {
    $scanner = $scanner.Source
}

Push-Location $PSScriptRoot
try {
    & $scanner `
        -Dsonar.organization=$org `
        -Dsonar.projectKey=$key `
        -Dsonar.host.url=https://sonarcloud.io `
        -Dsonar.token=$env:SONAR_TOKEN
}
finally {
    Pop-Location
}

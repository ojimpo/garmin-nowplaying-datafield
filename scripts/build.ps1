[CmdletBinding()]
param(
    [string]$SdkPath = $env:CIQ_SDK_HOME,
    [string]$KeyPath = $env:CIQ_DEVELOPER_KEY,
    [switch]$TestBuild
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $SdkPath) {
    $currentSdk = Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg'
    if (Test-Path -LiteralPath $currentSdk) {
        $SdkPath = (Get-Content -LiteralPath $currentSdk -Raw).Trim()
    }
}
if (-not $SdkPath -or -not (Test-Path -LiteralPath (Join-Path $SdkPath 'bin\monkeyc.bat'))) {
    throw 'Set CIQ_SDK_HOME or pass -SdkPath to a Connect IQ SDK directory.'
}
if (-not $KeyPath) { $KeyPath = Join-Path $projectRoot '.local\developer_key.der' }
if (-not (Test-Path -LiteralPath $KeyPath)) {
    throw 'Signing key missing. Run node scripts/generate-key.mjs first, or pass -KeyPath.'
}
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'bin') -Force | Out-Null
$outputName = if ($TestBuild) { 'nowplaying-tests.prg' } else { 'nowplaying.prg' }
$compilerArgs = @('-f', (Join-Path $projectRoot 'monkey.jungle'), '-d', 'edge530',
    '-o', (Join-Path $projectRoot "bin\$outputName"), '-y', $KeyPath, '-w', '-l', '3')
if ($TestBuild) { $compilerArgs += '-t' }
Push-Location $projectRoot
try {
    & (Join-Path $SdkPath 'bin\monkeyc.bat') @compilerArgs
    if ($LASTEXITCODE -ne 0) { throw "Connect IQ compiler failed ($LASTEXITCODE)." }
} finally { Pop-Location }

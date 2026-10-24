[CmdletBinding()]
param(
    [string]$SdkPath = $env:CIQ_SDK_HOME,
    [string]$KeyPath = $env:CIQ_DEVELOPER_KEY
)
$ErrorActionPreference = 'Stop'
# Negative probes intentionally return nonzero. Capture their diagnostics even
# when the calling PowerShell 7 session treats native exit codes as errors.
$PSNativeCommandUseErrorActionPreference = $false
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $SdkPath) {
    $active = Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg'
    if (Test-Path -LiteralPath $active) { $SdkPath = (Get-Content -LiteralPath $active -Raw).Trim() }
}
if (-not $SdkPath -or -not (Test-Path -LiteralPath (Join-Path $SdkPath 'bin\monkeyc.bat'))) {
    throw 'Set CIQ_SDK_HOME to a Windows Connect IQ SDK directory.'
}
if (-not $KeyPath) { $KeyPath = Join-Path $repoRoot '.local\developer_key.der' }
if (-not (Test-Path -LiteralPath $KeyPath)) { throw 'A local signing key is required. See README.md.' }
$workRoot = Join-Path $repoRoot 'build\ams-api-probes'
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
$probes = @(
    @{ name = 'ble-baseline'; expected = 0; api = 'Device.getServices'; code = 'device.getServices();' },
    @{ name = 'request-bond'; expected = 1; api = 'Device.requestBond'; code = 'device.requestBond();' },
    @{ name = 'bonded-devices'; expected = 1; api = 'BluetoothLowEnergy.getBondedDevices'; code = 'BluetoothLowEnergy.getBondedDevices();' }
)
$results = @()
foreach ($probe in $probes) {
    $probeRoot = Join-Path $workRoot $probe.name
    New-Item -ItemType Directory -Path $probeRoot -Force | Out-Null
    $manifest = @'
<?xml version="1.0" encoding="UTF-8"?>
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
  <iq:application id="a546a88a339d422eb5c4f78a94800cb2" type="datafield"
    name="@Strings.AppName" entry="ProbeApp" launcherIcon="@Drawables.LauncherIcon" minApiLevel="3.3.0">
    <iq:products><iq:product id="edge530"/></iq:products>
    <iq:permissions><iq:uses-permission id="BluetoothLowEnergy"/></iq:permissions>
    <iq:languages><iq:language>eng</iq:language></iq:languages><iq:barrels/>
  </iq:application>
</iq:manifest>
'@
    $source = @'
import Toybox.Application;
import Toybox.Activity;
import Toybox.BluetoothLowEnergy;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
class ProbeApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new ProbeView()];
    }
}
class ProbeView extends WatchUi.DataField {
    function initialize() { DataField.initialize(); }
    function compute(info as Activity.Info) as Void {}
    function onUpdate(dc as Graphics.Dc) as Void {}
}
// Compile-only capability check. Never called; not an AMS implementation.
function checkApi(device as BluetoothLowEnergy.Device) as Void {
    __PROBE_CODE__
}
'@
    Set-Content -LiteralPath (Join-Path $probeRoot 'manifest.xml') -Value $manifest -Encoding utf8
    Set-Content -LiteralPath (Join-Path $probeRoot 'Probe.mc') -Value $source.Replace('__PROBE_CODE__', $probe.code) -Encoding utf8
    $resources = (Join-Path $repoRoot 'resources').Replace('\', '/')
    $jungle = "project.manifest = manifest.xml`nbase.sourcePath = .`nbase.resourcePath = $resources`n"
    Set-Content -LiteralPath (Join-Path $probeRoot 'monkey.jungle') -Value $jungle -Encoding utf8
    $compilerArgs = @('-f', (Join-Path $probeRoot 'monkey.jungle'), '-d', 'edge530',
        '-o', (Join-Path $probeRoot 'probe.prg'), '-y', $KeyPath, '-w', '-l', '3')
    $output = (& (Join-Path $SdkPath 'bin\monkeyc.bat') @compilerArgs 2>&1 | Out-String).Trim()
    $code = $LASTEXITCODE
    $matched = if ($probe.expected -eq 0) { $code -eq 0 -and $output -match 'BUILD SUCCESSFUL' } else {
        # An unrelated build error must not count as evidence of an unsupported API.
        $code -ne 0 -and $output -match "not supported for device 'edge530'" -and
            $output -match [regex]::Escape($probe.api)
    }
    $results += [ordered]@{
        probe = $probe.name
        sourceStatement = $probe.code
        exitCode = $code
        expectedOutcome = $(if ($probe.expected -eq 0) { 'BUILD SUCCESSFUL' } else { 'Unsupported API compilation failure' })
        expectationMet = $matched
        compilerOutput = $output.Replace($repoRoot, '<repository>').Replace($SdkPath, '<sdk>')
    }
}
$report = [ordered]@{
    sdkVersion = (Get-Content -LiteralPath (Join-Path $SdkPath 'bin\version.txt') -Raw).Trim()
    target = 'edge530'
    typecheck = 'strict (-l 3)'
    scope = 'Compilation only. No BLE scan, connection, pairing, or iPhone communication is performed.'
    results = $results
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $workRoot 'results.json') -Encoding utf8
$report | ConvertTo-Json -Depth 8
if ($results | Where-Object { -not $_.expectationMet }) { throw 'Unexpected result: inspect compilerOutput before drawing a conclusion.' }

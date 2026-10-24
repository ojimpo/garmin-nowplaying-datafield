[CmdletBinding()]
param(
    [string]$DeviceDirectory = (Join-Path $env:APPDATA 'Garmin\ConnectIQ\Devices\edge530')
)
$ErrorActionPreference = 'Stop'
$definition = Get-Content -LiteralPath (Join-Path $DeviceDirectory 'compiler.json') -Raw | ConvertFrom-Json
if ($definition.deviceId -ne 'edge530') { throw 'This audit must use the official edge530 definition.' }
[xml]$api = Get-Content -LiteralPath (Join-Path $DeviceDirectory 'edge530.api.debug.xml') -Raw
$symbols = @($api.debugInfo.symbolTable.entry | ForEach-Object { $_.GetAttribute('symbol') })
$scopes = @($api.debugInfo.apiScopes.apiScopeEntry | ForEach-Object { $_.GetAttribute('label') })
$bleFunctions = @($api.debugInfo.functions.functionEntry |
    Where-Object { $_.GetAttribute('parent') -eq 'BluetoothLowEnergy' -and $_.GetAttribute('name') -ne '<init>' } |
    ForEach-Object { $_.GetAttribute('name') } | Sort-Object -Unique)
$checks = [ordered]@{}
foreach ($name in @('getPairedDevices', 'pairDevice', 'registerProfile', 'setScanState',
        'requestBond', 'isBonded', 'getBondedDevices', 'setConnectionStrategy')) {
    $checks[$name] = $symbols -contains $name
}
[ordered]@{
    deviceId = $definition.deviceId
    definitionVersion = $definition.deviceVersion
    apiVersions = @($definition.partNumbers | ForEach-Object { $_.connectIQVersion } | Sort-Object -Unique)
    checks = $checks
    publicBleModuleFunctions = $bleFunctions
    mediaApiScopePresent = [bool]($scopes | Where-Object { $_ -eq 'Toybox_Media' -or $_ -like 'Toybox_Media_*' })
    scope = 'Static inspection of the official public API debug metadata; not a Bluetooth connection test.'
} | ConvertTo-Json -Depth 8

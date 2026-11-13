<#
.SYNOPSIS
Returns the SOURCE tenant settings that maintainers use to export content into this repo.
.DESCRIPTION
The source tenant is where the template sites are built. Only people maintaining
this repo need it; people applying a template use their own destination tenant.

Values resolve in this order, first match wins:
  1. -Tenant / -ClientId parameters
  2. PNP_SOURCE_TENANT / PNP_SOURCE_CLIENT_ID environment variables
  3. Sites.<SiteName> in utils\source.config.json
  4. Top-level Tenant / ClientId in utils\source.config.json

utils\source.config.json is git-ignored. Copy utils\source.config.sample.json to create it.
.OUTPUTS
PSCustomObject with Tenant and ClientId.
#>
[CmdletBinding()]
param(
    [string]$SiteName,
    [string]$Tenant,
    [string]$ClientId,
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'source.config.json')
)

$config = $null
if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
    $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
}

$siteConfig = $null
if ($config -and $SiteName -and $config.PSObject.Properties['Sites']) {
    $siteConfig = $config.Sites.PSObject.Properties |
        Where-Object { $_.Name -eq $SiteName } |
        Select-Object -ExpandProperty Value -First 1
}

function Resolve-Setting([string]$Explicit, [string]$EnvName, [string]$Key) {
    if ($Explicit) { return $Explicit }
    $fromEnv = [Environment]::GetEnvironmentVariable($EnvName)
    if ($fromEnv) { return $fromEnv }
    if ($siteConfig -and $siteConfig.PSObject.Properties[$Key] -and $siteConfig.$Key) { return [string]$siteConfig.$Key }
    if ($config -and $config.PSObject.Properties[$Key] -and $config.$Key) { return [string]$config.$Key }
}

$resolvedTenant = Resolve-Setting $Tenant 'PNP_SOURCE_TENANT' 'Tenant'
$resolvedClientId = Resolve-Setting $ClientId 'PNP_SOURCE_CLIENT_ID' 'ClientId'

$missing = @()
if (!$resolvedTenant) { $missing += 'Tenant' }
if (!$resolvedClientId) { $missing += 'ClientId' }
if ($missing) {
    throw "Source $($missing -join ' and ') not set. Pass -Tenant/-ClientId, set PNP_SOURCE_TENANT/PNP_SOURCE_CLIENT_ID, or create utils\source.config.json from utils\source.config.sample.json."
}
if ($resolvedTenant -notmatch '^[a-zA-Z0-9][a-zA-Z0-9-]*$') {
    throw "Source tenant '$resolvedTenant' must be the tenant name only, without .onmicrosoft.com or .sharepoint.com."
}
if ($resolvedClientId -notmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') {
    throw "Source ClientId '$resolvedClientId' is not a GUID."
}

[pscustomobject]@{ Tenant = $resolvedTenant; ClientId = $resolvedClientId }

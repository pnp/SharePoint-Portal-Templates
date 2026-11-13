[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The template name; the font package is titled SiteName or SiteName.Fonts.

    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

$adminConnection = Connect-PnPOnline -ClientId $ClientId -Url "https://$($Tenant)-admin.sharepoint.com" -Interactive -ReturnConnection

$config = Get-PnPBrandCenterConfig -Connection $adminConnection

$siteConnection = Connect-PnPOnline -Connection $adminConnection -Url $config.SiteUrl -ReturnConnection
$fontPackages = Get-PnPBrandCenterFontPackage -Connection $siteConnection

$fontPackage = $fontPackages | Where-Object { $_.Title -eq $SiteName -or $_.Title -eq "$SiteName.Fonts" }
if (!$fontPackage) { throw "No font package titled '$SiteName' or '$SiteName.Fonts' was found." }
$outputPath = ".\utils\Font Packages\$($SiteName).Fonts.json"
$fontPackage | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding utf8 -Force

& "$PSScriptRoot\Remove-TenantIdentity.ps1" -Path $outputPath


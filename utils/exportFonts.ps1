[CmdletBinding()]
param(
    [string]$SiteName, # Optional; selects a Sites.<name> entry in utils\source.config.json.
    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

#region Connect to Brand Center Site
# Connect to the Brand Center site
# Fonts are stored in the hidden Fonts list in the Brand Center site

$brandCenterSiteUrl = "https://$($Tenant).sharepoint.com/sites/BrandGuide"
$brandCenterSiteConnection = Connect-PnPOnline -ClientId $ClientId -Url $brandCenterSiteUrl -Interactive -ReturnConnection

Get-PnPList -Connection $brandCenterSiteConnection

$fonts = Get-PnPListItem -Connection $brandCenterSiteConnection -List "Fonts"

# Save font info
$fontInfo = $fonts | Select-Object -Property Title, FieldValues
$fontInfo | ConvertTo-Json -Depth 5 | Out-File ".\utils\Fonts\Fonts.json" -Encoding utf8 -Force
& "$PSScriptRoot\Remove-TenantIdentity.ps1" -Path ".\utils\Fonts\Fonts.json"

# Get font files
$destinationPath = ".\utils\Fonts"

foreach ($font in $fontInfo) {
    $fontUrl = $font.FieldValues.FileRef
    $fileName = $font.FieldValues.FileLeafRef

    Get-PnPFile -Connection $brandCenterSiteConnection -Url $fontUrl -Path $destinationPath -FileName $fileName -AsFile -Force
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The template name; its brand colors are prefixed with this name.

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

$colors = Get-PnPListItem -Connection $siteConnection -List "_SPBrandColors"

#region Export Brand Colors
# Keep only the fields setupTenant.ps1 reads, so no author or tenant details are exported.
$brandColors = $colors | Where-Object { $_.FieldValues._SPColorTitle -like "$SiteName*" }
$palette = $brandColors | ForEach-Object {
    [ordered]@{
        FieldValues = [ordered]@{
            _SPColorTitle   = $_.FieldValues._SPColorTitle
            _SPColorVisible = $_.FieldValues._SPColorVisible
            _SPColorCode    = $_.FieldValues._SPColorCode
        }
    }
}
$outputPath = ".\utils\Brand Colors\$($SiteName).Colors.json"
ConvertTo-Json -InputObject @($palette) -Depth 5 | Out-File $outputPath -Encoding utf8 -Force
#endregion


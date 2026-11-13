[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The template name; used for the output file name.

    [string]$SourceSite, # The URL name of the source site. Omit to export from the tenant root site.
    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

# region Export Resources
$siteUrl = "https://$($Tenant).sharepoint.com/"
if ($SourceSite) { $siteUrl += "sites/$($SourceSite)" }
$siteConnection = Connect-PnPOnline -ClientId $ClientId -Url $siteUrl -Interactive -ReturnConnection


$config = Get-PnPListItem `
    -Connection $siteConnection `
    -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" `
    -Id 1

# Get the Spotlight configuration
$resources = [PSCustomObject]@{
    Title = "Spotlight_x0020_Configuration"
    Value = $config.FieldValues["Spotlight_x0020_Configuration"]
}

$resources | Export-Csv -Path "./utils/Resources/$($SiteName).Resources.csv" -NoTypeInformation -Force

& "$PSScriptRoot\Remove-TenantIdentity.ps1" -Path "./utils/Resources/$($SiteName).Resources.csv"

# endregion

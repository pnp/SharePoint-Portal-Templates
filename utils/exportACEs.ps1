[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The template name; used for the output file name.

    [string]$SourceSite, # The URL name of the source site in the source tenant. Defaults to SiteName.
    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId
if (!$SourceSite) { $SourceSite = $SiteName }

# region Export Resources
$siteUrl = "https://$($Tenant).sharepoint.com/sites/$($SourceSite)"
$siteConnection = Connect-PnPOnline -ClientId $ClientId -Url $siteUrl -Interactive -ReturnConnection

$siteACES = Get-PnPVivaConnectionsDashboardACE -Connection $siteConnection

# Export $siteACES to a CSV file

 $siteACES | Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties |
    ForEach-Object {
        $_.JsonProperties = $_.JsonProperties -ireplace [regex]::Escape($siteUrl), '{site}/'
        $_
    } |
    Export-Csv -Path "$PSScriptRoot/ACES/$($SiteName).ACEs.csv" -NoTypeInformation

& "$PSScriptRoot\Remove-TenantIdentity.ps1" -Path "$PSScriptRoot/ACES/$($SiteName).ACEs.csv"

# endregion



[CmdletBinding()]
param(
    [string]$SourceSite = 'Credimus', # The URL name of the source site.
    [string]$Tenant,
    [string]$ClientId
)

# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force # Recommended version: 3.3.0 and above

# Maintainer script: exports from the SOURCE tenant. Settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\..\..\utils\Get-SourceConfig.ps1" -SiteName 'Credimus' -Tenant $Tenant -ClientId $ClientId
$templateSiteUrl = "https://$($source.Tenant).sharepoint.com/sites/$($SourceSite)"
$templateSiteConnection = Connect-PnPOnline -ClientId $source.ClientId -Url $templateSiteUrl -Interactive -ReturnConnection

Get-PnPSiteTemplate `
    -Connection $templateSiteConnection `
    -Configuration "./templates/Credimus/_exportConfig/PnPSite.json" `
    -IncludeAllPages `
    -Out "./templates/Credimus/PnPProvisioning/PnP-Provisioning-CredimusSite.xml" `
    -Force

# Remove the Dashboard.aspx page from the template's XML file, as it will be created by the Viva Connections experience setup
[xml]$xml = Get-Content "./templates/Credimus/PnPProvisioning/PnP-Provisioning-CredimusSite.xml"

$xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage | ForEach-Object {
    if ($_.PageName -like "dashboard*.aspx") {
        $xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.RemoveChild($_) | Out-Null
        Write-Host -BackgroundColor Cyan "Removed Dashboard.aspx page from the template XML file."
    }
}
$xml.Save("./templates/Credimus/PnPProvisioning/PnP-Provisioning-CredimusSite.xml")

# Remove source tenant names and user domains from the exported XML before it is committed
& "$PSScriptRoot\..\..\utils\Remove-TenantIdentity.ps1" -Path "./templates/Credimus/PnPProvisioning/PnP-Provisioning-CredimusSite.xml"

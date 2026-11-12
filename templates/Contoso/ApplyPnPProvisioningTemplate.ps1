# Requirements:
#   PowerShell 7.x
#   PnP.PowerShell module
#   PnP.PowerShell App Registration
#   Global Admin or SharePoint Admin permissions
#
# Usage:
#   .\ApplyPnPProvisioningTemplate.ps1 -Tenant contoso -ClientId <your-app-id> -SiteUrl <site-url-name>

[CmdletBinding()]
param(
    # Your tenant name, without the .onmicrosoft.com or .com suffix (for example, contoso).
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]*$')]
    [string]$Tenant,

    # The App (client) ID of your Entra ID app registration for PnP.PowerShell.
    [Parameter(Mandatory)]
    [guid]$ClientId,

    # The URL name of the site you created for this template (the part after /sites/).
    [Parameter(Mandatory)]
    [string]$SiteUrl
)

#region Setup
# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force
#endregion

#region Connections
# Calculated variables
$adminUrl = "https://$($tenant)-admin.sharepoint.com/"
$destinationUrl = "https://$($tenant).sharepoint.com/sites/$($siteUrl)"

$adminConnection = Connect-PnPOnline -ClientId $clientId -Url $adminUrl -Interactive -ReturnConnection

$newSite = Get-PnPTenantSite -Connection $adminConnection -Identity $destinationUrl

if (!$newSite) {
    Write-Host -BackgroundColor Cyan "Site at $destinationUrl does not exist"
    return
}
else {
    Write-Host -BackgroundColor Cyan "Connecting to existing site at $destinationUrl..."
}

$newSiteConnection = Connect-PnPOnline -ClientId $clientId -Url $destinationUrl -Interactive -ReturnConnection
#endregion

#region Apply PnP Template
Write-Host -BackgroundColor Cyan "Applying PnP Provisioning Template to site at $destinationUrl..."

# Apply PnP Template
Invoke-PnPSiteTemplate `
    -Connection $newSiteConnection `
    -Path "$PSScriptRoot/PnPProvisioning/PnP-Provisioning-Clean.xml"

#endregion

#region Additional configuration
#### Additional configuration that can't be done in the template for technical reasons ####
Write-Host -BackgroundColor Cyan "Performing additional configuration for site at $destinationUrl..."

# Set site header background image and other settings
Set-PnPWebHeader -Connection $newSiteConnection `
    -HeaderLayout Standard `
    -HeaderBackgroundImageUrl "SiteAssets/__extendedHeaderBackgroundImage__DEFAULT_CHROME_BG_IMAGE_NAME.png" `
    -SiteThumbnailUrl "SiteAssets/__sitelogo__Logo.png" `
    -SiteLogoUrl "SiteAssets/__sitelogo__Logo.png"
Set-PnPWeb -Connection $newSiteConnection -HideTitleInHeader

# Add the correct ACES to the Viva Connections Dashboard
$aces = Import-Csv -Path "$PSScriptRoot/ACEs/Contoso.ACEs.csv"

Write-Host -BackgroundColor Cyan "Setting up $($aces.Count) ACES on the Dashboard"

# Replace all instances of {site} in the $resources with the actual site URL
$aces | ForEach-Object {
    $_.JsonProperties = $_.JsonProperties -replace "{site}", $destinationUrl
}

$badACEs = Get-PnPVivaConnectionsDashboardACE -Connection $newSiteConnection
foreach ($badACE in $badACEs) {
    Remove-PnPVivaConnectionsDashboardACE -Connection $newSiteConnection -Identity $badACE
}

foreach ($ace in $aces) {
    Add-PnPVivaConnectionsDashboardACE `
        -Connection $newSiteConnection `
        -Identity $ace.ACEType `
        -Order $ace.Order `
        -Title $ace.Title `
        -PropertiesJSON $ace.JsonProperties `
        -CardSize $ace.CardSize
}

# Resources
$lists = Get-PnPList -Connection $newSiteConnection
$vcList = ($lists | Where-Object { $_.Title -like "ConnectionsConfiguration*" }).Title

# Import the file Contoso.Resources.csv with the resources to add to the Resources list
$resources = Import-Csv -Path "$PSScriptRoot/Resources/Contoso.Resources.csv"

Write-Host -BackgroundColor Cyan "Setting up $($resources.Count) resources on the Dashboard"

# Replace all instances of {site} in the $resources with the actual site URL
$resources | ForEach-Object {
    $_.Value = $_.Value -replace "{site}", $destinationUrl
}

Set-PnPListItem -Connection $newSiteConnection -List $vcList -Identity 1 -Values @{
    Spotlight_x0020_Configuration = $resources.Value
}

Write-Host -BackgroundColor Cyan "Provisioning complete for site at $destinationUrl"
#endregion
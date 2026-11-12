[CmdletBinding()]
param(
    [string]$SiteName = 'Solbound', # The URL name of the source site, also the template folder name.
    [string]$Tenant,
    [string]$ClientId
)

# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force # Recommended version: 3.3.0 and above

# Maintainer script: exports from the SOURCE tenant. Settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\..\..\utils\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$templateSiteUrl = "https://$($source.Tenant).sharepoint.com/sites/$($SiteName)"
$templateSiteConnection = Connect-PnPOnline -ClientId $source.ClientId -Url $templateSiteUrl -Interactive -ReturnConnection

Get-PnPSiteTemplate `
    -Connection $templateSiteConnection `
    -Configuration "./templates/$($siteName)/_exportConfig/PnPSite.json" `
    -IncludeAllPages `
    -Out "./templates/$($siteName)/PnPProvisioning/PnP-Provisioning.xml" `
    -Force

# Remove the Dashboard.aspx page from the template's XML file, as it will be created by the Viva Connections experience setup
[xml]$xml = Get-Content "./templates/$($siteName)/PnPProvisioning/PnP-Provisioning.xml"

$xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage | ForEach-Object {
    if ($_.PageName -like "dashboard*.aspx") {
        $xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.RemoveChild($_) | Out-Null
        Write-Host -BackgroundColor Cyan "Removed Dashboard.aspx page from the template XML file."
    }
}
$xml.Save("./templates/$($siteName)/PnPProvisioning/PnP-Provisioning.xml")

# Remove the MediaServiceImageTags from the export to eliminate Term Store mismatches and errors
$sourcePath = "./templates/$($siteName)/PnPProvisioning/PnP-Provisioning.xml"
$cleanPath  = "./templates/$($siteName)/PnPProvisioning/PnP-Provisioning-Clean.xml"

Copy-Item $sourcePath $cleanPath -Force

[xml]$template = Get-Content -Path $cleanPath -Raw

$nodes = $template.SelectNodes(
    "//*[" +
        "(local-name()='FieldRef' and @Name='MediaServiceImageTags') or " +
        "(local-name()='Field' and " +
            "(@Name='MediaServiceImageTags' or @InternalName='MediaServiceImageTags')) or " +
        "(local-name()='Property' and " +
            "(@Key='MediaServiceImageTags' or @Name='MediaServiceImageTags'))" +
    "]"
)

foreach ($node in @($nodes)) {
    [void]$node.ParentNode.RemoveChild($node)
}

$template.Save($cleanPath)

Write-Host "Removed $($nodes.Count) MediaServiceImageTags nodes."

# Clean up site-specific URLs from the template and replace with {site} tokens
$content = Get-Content $cleanPath -Raw

$content = $content -replace `
    'https://[^/]+\.sharepoint\.com\{site\}',
    '{site}'
$content = $content -replace `
    'https://[^/]+\.sharepoint\.com',
    '{site}/'

Set-Content $cleanPath $content

# Remove source tenant names and user domains from the exported XML before it is committed
& "$PSScriptRoot\..\..\utils\Remove-TenantIdentity.ps1" -Path $sourcePath, $cleanPath

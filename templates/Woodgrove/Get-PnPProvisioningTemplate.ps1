# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force # Recommended version: 3.3.0 and above

$templateTenant = "M365x80643879" # Your tenant name, without the .onmicrosoft.com or .com suffix
$siteName = "Woodgrove" # The name of the site you want to export
$templateSiteUrl = "https://$($templateTenant).sharepoint.com/sites/hello3"
$clientId = "0241da54-30d1-48da-8a55-d38d3d7f7863"
$templateSiteConnection = Connect-PnPOnline -ClientId $clientId -Url $templateSiteUrl -Interactive -ReturnConnection

Get-PnPSiteTemplate `
    -Connection $templateSiteConnection `
    -Configuration "./templates/Woodgrove/_exportConfig/PnPSite.json" `
    -IncludeAllPages `
    -Out "./templates/Woodgrove/PnPProvisioning/PnP-Provisioning.xml" `
    -Force

# Remove the Dashboard.aspx page from the template's XML file, as it will be created by the Viva Connections experience setup
[xml]$xml = Get-Content "./templates/Woodgrove/PnPProvisioning/PnP-Provisioning.xml"

$xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage | ForEach-Object {
    if ($_.PageName -like "dashboard*.aspx") {
        $xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.RemoveChild($_) | Out-Null
        Write-Host -BackgroundColor Cyan "Removed Dashboard.aspx page from the template XML file."
    }
}
$xml.Save("./templates/Woodgrove/PnPProvisioning/PnP-Provisioning.xml")


# Remove the MediaServiceImageTags from the export to eliminate Term Store mismatches and errors
$sourcePath = "./templates/Woodgrove/PnPProvisioning/PnP-Provisioning.xml"
$cleanPath  = "./templates/Woodgrove/PnPProvisioning/PnP-Provisioning-Clean.xml"

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


$content = Get-Content $cleanPath -Raw

$content = $content -replace `
    'https://[^/]+\.sharepoint\.com\{site\}',
    '{site}'

Set-Content $cleanPath $content

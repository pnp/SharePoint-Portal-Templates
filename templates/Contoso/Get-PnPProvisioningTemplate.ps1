# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force # Recommended version: 3.3.0 and above

$templateTenant = "M365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$siteName = "Contoso" # The name of the site you want to export
$templateSiteUrl = "https://$($templateTenant).sharepoint.com" #/sites/hello3"
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0"
$templateSiteConnection = Connect-PnPOnline -ClientId $clientId -Url $templateSiteUrl -Interactive -ReturnConnection

Get-PnPSiteTemplate `
    -Connection $templateSiteConnection `
    -Configuration "./templates/Contoso/_exportConfig/PnPSite.json" `
    -IncludeAllPages `
    -Out "./templates/Contoso/PnPProvisioning/PnP-Provisioning.xml" `
    -Force

# Remove the Dashboard.aspx page from the template's XML file, as it will be created by the Viva Connections experience setup
[xml]$xml = Get-Content "./templates/Contoso/PnPProvisioning/PnP-Provisioning.xml"

$xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage | ForEach-Object {
    if ($_.PageName -like "dashboard*.aspx") {
        $xml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.RemoveChild($_) | Out-Null
        Write-Host -BackgroundColor Cyan "Removed Dashboard.aspx page from the template XML file."
    }
}
$xml.Save("./templates/Contoso/PnPProvisioning/PnP-Provisioning.xml")


# Remove the MediaServiceImageTags from the export to eliminate Term Store mismatches and errors
$sourcePath = "./templates/Contoso/PnPProvisioning/PnP-Provisioning.xml"
$cleanPath  = "./templates/Contoso/PnPProvisioning/PnP-Provisioning-Clean.xml"

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

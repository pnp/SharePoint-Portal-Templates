# Load PnP.PowerShell, if it isn't already
Import-Module PnP.PowerShell -Force # Recommended version: 3.3.0 and above

$templateTenant = "spex003" # Your tenant name, without the .onmicrosoft.com or .com suffix
$templateSiteUrl = "https://$($templateTenant).sharepoint.com/sites/Credimus"
$templateSiteConnection = Connect-PnPOnline -ClientId e6f6cea5-3653-448b-b4fc-5ddb2a4b376f -Url $templateSiteUrl -Interactive -ReturnConnection

Get-PnPSiteTemplate `
    -Connection $templateSiteConnection `
    -Configuration "./templates/Credimus/_exportConfig/PnPCredimusSite.json" `
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

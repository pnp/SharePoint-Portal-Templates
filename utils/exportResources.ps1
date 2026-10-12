Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0" # The App Id from your App Registration for PnP.PowerShell
$siteName = "hello3" # The URL name for the site you want to update.
#endregion

# region Export Resources
$siteUrl = "https://$($tenant).sharepoint.com/" #sites/$($siteName)"
$siteConnection = Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Interactive -ReturnConnection


$config = Get-PnPListItem `
    -Connection $siteConnection `
    -List "ConnectionsConfiguration-4ce1892f-76d2-4393-b9df-079a66a95c4a" `
    -Id 1

# Get the Spotlight configuration
$resources = [PSCustomObject]@{
    Title = "Spotlight_x0020_Configuration"
    Value = $config.FieldValues["Spotlight_x0020_Configuration"]
}

$resources | Export-Csv -Path "./utils/Resources/$($siteName).Resources.csv" -NoTypeInformation -Force

# endregion

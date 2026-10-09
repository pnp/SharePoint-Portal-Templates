Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "span001" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "781d6ed3-0279-412e-af06-acfa99f57819" # The App Id from your App Registration for PnP.PowerShell
$siteName = "<YOUR_SITE_URL>" # The URL name for the site you want to update.
#endregion

# region Export Resources
$siteUrl = "https://$($tenant).sharepoint.com/sites/$($siteName)"
$siteConnection = Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Interactive -ReturnConnection

$siteACES = Get-PnPVivaConnectionsDashboardACE -Connection $siteConnection

# Export $siteACES to a CSV file
$siteACES | `
    Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties | `
    Export-Csv -Path "./utils/ACES/$($siteName).ACEs.csv" -NoTypeInformation -Encoding UTF8 -Force

# endregion

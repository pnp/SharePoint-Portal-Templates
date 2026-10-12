Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "M365x80643879" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "0241da54-30d1-48da-8a55-d38d3d7f7863
" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Hello3" # The URL name for the site you want to update.
#endregion

# region Export Resources
$siteUrl = "https://$($tenant).sharepoint.com/sites/$($siteName)"
$siteConnection = Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Interactive -ReturnConnection

$siteACES = Get-PnPVivaConnectionsDashboardACE -Connection $siteConnection

# Export $siteACES to a CSV file

 $siteACES | Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties |
    ForEach-Object {
        $_.JsonProperties = $_.JsonProperties -ireplace [regex]::Escape($siteUrl), '{site}'
        $_
    } |
    Export-Csv -Path "./utils/ACES/$($siteName).ACEs.csv" -NoTypeInformation

# endregion

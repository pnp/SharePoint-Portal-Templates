Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "M365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Contoso" # The URL name for the site you want to update.
#endregion


#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "span001" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "781d6ed3-0279-412e-af06-acfa99f57819" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Contoso" # The name of the site you want to update.
$siteUrl = "MARCTEST3" # The URL name for the site you want to update.
#endregion

# region Export Resources
$siteUrl = "https://$($tenant).sharepoint.com/sites/$($siteUrl)"
$siteConnection = Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Interactive -ReturnConnection

$siteACES = Get-PnPVivaConnectionsDashboardACE -Connection $siteConnection

# Export $siteACES to a CSV file

 $siteACES | Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties |
    ForEach-Object {
        $_.JsonProperties = $_.JsonProperties -ireplace [regex]::Escape($siteUrl), '{site}/'
        $_
    } |
    Export-Csv -Path "$PSScriptRoot/ACES/$($siteName).ACEs.csv" -NoTypeInformation

# endregion



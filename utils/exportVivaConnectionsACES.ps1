Import-Module PnP.PowerShell -Force
Import-Module ./PowerShell/UtilityFunctions.psm1 -Force

Add-SympVariables

# Credimus
$credimusUrl = "https://$($tenant).sharepoint.com/sites/Credimus"
$credimusConnection = Connect-PnPOnline -ClientId $clientId -Url $credimusUrl -Interactive -ReturnConnection

$credimusACES = Get-PnPVivaConnectionsDashboardACE -Connection $credimusConnection 

# Export $credimusACEs to a CSV file
$credimusACES | Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties | Export-Csv -Path "./SPEX002/ACES/Credimus.ACEs.csv" -NoTypeInformation -Encoding UTF8 -Force


# Solbound
$solboundUrl = "https://$($tenant).sharepoint.com/sites/Solbound"
$solboundConnection = Connect-PnPOnline -ClientId $clientId -Url $solboundUrl -Interactive -ReturnConnection

$solboundACES = Get-PnPVivaConnectionsDashboardACE -Connection $solboundConnection

# Export $solboundACES to a CSV file
$solboundACES | Select-Object -Property Order, ACEType, Title, CardSize, Description, JsonProperties | Export-Csv -Path "./SPEX002/ACES/Solbound.ACEs.csv" -NoTypeInformation -Encoding UTF8 -Force




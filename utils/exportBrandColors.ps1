Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "span001" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "781d6ed3-0279-412e-af06-acfa99f57819" # Replace with your actual client ID
$siteName = "Contoso" # The URL name for the site you want to update.
#endregion

$adminConnection = Connect-PnPOnline -ClientId $clientId -Url "https://$($tenant)-admin.sharepoint.com" -Interactive -ReturnConnection

$config = Get-PnPBrandCenterConfig -Connection $adminConnection

$siteConnection = Connect-PnPOnline -Connection $adminConnection -Url $config.SiteUrl -ReturnConnection

$colors = Get-PnPListItem -Connection $siteConnection -List "_SPBrandColors"

#region Export Brand Colors
$brandColors = $colors | Where-Object { $_.FieldValues._SPColorTitle -like "$siteName*" }
$palette = $brandColors | Select-Object -Property FieldValues
$palette | ConvertTo-Json -Depth 5 | Out-File ".\utils\Brand Colors\$($siteName).Colors.json" -Encoding utf8 -Force
#endregion

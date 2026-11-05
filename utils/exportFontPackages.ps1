Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "span001" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "781d6ed3-0279-412e-af06-acfa99f57819" # Replace with your actual client ID
$siteName = "Credimus" # The URL name for the site you want to update.
#endregion

$adminConnection = Connect-PnPOnline -ClientId $clientId -Url "https://$($tenant)-admin.sharepoint.com" -Interactive -ReturnConnection

$config = Get-PnPBrandCenterConfig -Connection $adminConnection

$siteConnection = Connect-PnPOnline -Connection $adminConnection -Url $config.SiteUrl -ReturnConnection
$fontPackages = Get-PnPBrandCenterFontPackage -Connection $siteConnection

$fontPackages = Get-PnPBrandCenterFontPackage -Connection $siteConnection

$fontPackage = $fontPackages | Where-Object { $_.Title -eq $siteName }
$fontPackageJson = $fontPackage | ConvertTo-Json -Depth 10
$fontPackageJson | Out-File ".\utils\FontPackages\$($siteName).Fonts.json" -Encoding utf8 -Force


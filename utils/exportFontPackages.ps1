# See:  https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-theming/sharepoint-site-theming-overview
#       https://fluentuipr.z22.web.core.windows.net/heads/master/theming-designer/index.html

Import-Module Microsoft.Online.SharePoint.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "M365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$siteName = "Contoso 4" # The URL name for the site you want to update.
#endregion

Connect-SPOService -Url "https://$($tenant)-admin.sharepoint.com" -ModernAuth $true -UseSystemBrowser $true

$fontPackages = Get-SPOFontPackage

Get-PnPBrandCenterConfig -Connection $siteConnection

$fontPackages = Get-PnPBrandCenterFontPackage -Connection $siteConnection

$fontPackage = $fontPackages | Where-Object { $_.Title -eq $siteName }
$fontPackageJson = $fontPackage | ConvertTo-Json -Depth 10
$fontPackageJson | Out-File ".\utils\FontPackages\$($siteName).Fonts.json" -Encoding utf8 -Force


Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x80643879" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "0241da54-30d1-48da-8a55-d38d3d7f7863" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Contoso 4" # The URL name for the site you want to update.
#endregion



Get-PnPBrandCenterConfig -Connection $siteConnection



#region Export Theme
$theme = Get-SPOTheme -IncludeGlobalTheme -Name "$($siteName).Theme"
$themeJson = $theme | ConvertTo-Json -Depth 10
$themeJson | Out-File ".\utils\Themes\$($siteName).Theme.json" -Encoding utf8 -Force
#endregion

Import-Module PnP.PowerShell -Force
#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "M365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Contoso 4" # The URL name for the site you want to update.
#endregion

#region Connect to Brand Center Site
# Connect to the Brand Center site
# Fonts are stored in the hidden Fonts list in the Brand Center site

$brandCenterSiteUrl = "https://$($tenant).sharepoint.com/sites/BrandGuide"
$brandCenterSiteConnection = Connect-PnPOnline -ClientId $clientId -Url $brandCenterSiteUrl -Interactive -ReturnConnection

Get-PnPList -Connection $brandCenterSiteConnection

$fonts = Get-PnPListItem -Connection $brandCenterSiteConnection -List "Fonts"

# Save font info
$fontInfo = $fonts | Select-Object -Property Title, FieldValues
$fontInfo | ConvertTo-Json -Depth 5 | Out-File ".\utils\Fonts\Fonts.json" -Encoding utf8 -Force

# Get font files
$destinationPath = ".\utils\Fonts"

foreach ($font in $fontInfo) {
    $fontUrl = $font.FieldValues.FileRef
    $fileName = $font.FieldValues.FileLeafRef

    Get-PnPFile -Connection $brandCenterSiteConnection -Url $fontUrl -Path $destinationPath -FileName $fileName -AsFile -Force
}
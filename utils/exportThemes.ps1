# Exports a named site-local theme without changing the site or tenant themes.
Import-Module PnP.PowerShell -Force -ErrorAction Stop

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x80643879" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "0241da54-30d1-48da-8a55-d38d3d7f7863" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Hello3" # The URL name of the source site.
$themeName = "Woodgrove" # Must match the local theme name exactly.
#endregion

$adminConnection = Connect-PnPOnline -ClientId $clientId -Url "https://$($tenant)-admin.sharepoint.com" -Interactive -ReturnConnection

$siteConnection = Connect-PnPOnline -Connection $adminConnection -Url "https://$($tenant).sharepoint.com/sites/$siteName" -ReturnConnection -ErrorAction Stop

#region Export Theme
$context = Get-PnPContext -Connection $siteConnection -ErrorAction Stop
$brandCenter = [Microsoft.SharePoint.Client.BrandCenter]::new($context)
$siteThemes = $brandCenter.GetSiteThemes()
Invoke-PnPQuery -Connection $siteConnection -ErrorAction Stop

if ($null -eq $siteThemes.Value) {
    throw "SharePoint returned no local theme response for site '$siteName'."
}
$themes = @($siteThemes.Value.themeData | Where-Object { $_.name -eq $themeName })
if ($themes.Count -ne 1) {
    $availableThemes = @($siteThemes.Value.themeData | ForEach-Object { $_.name })
    throw "Expected one local theme named '$themeName'; found $($themes.Count). Available local themes: $($availableThemes -join ', ')."
}

$themeJson = $themes[0].themeJson
if ([string]::IsNullOrWhiteSpace($themeJson)) {
    throw "Local theme '$themeName' has no theme definition."
}
$theme = ConvertFrom-Json -InputObject $themeJson -ErrorAction Stop
if ($null -eq $theme -or $theme -isnot [System.Management.Automation.PSCustomObject]) {
    throw "Local theme '$themeName' must contain a JSON object."
}

$outputFolder = "./utils/Themes"
New-Item -Path $outputFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
$outputPath = Join-Path $outputFolder "$siteName.Theme.json"
Set-Content -LiteralPath $outputPath -Value $themeJson -Encoding utf8 -ErrorAction Stop
Write-Host "Exported local theme '$themeName' from '$siteName' to '$outputPath'."
#endregion

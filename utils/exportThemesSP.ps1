Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0" # The App Id from your App Registration for PnP.PowerShell
$themeName = "Contoso 3"
#endregion

$siteConnection = Connect-PnPOnline -Url "https://$tenant.sharepoint.com" -ClientId $clientId -Interactive -ReturnConnection


#region Export Theme
$response = Invoke-PnPSPRestMethod `
    -Connection $siteConnection `
    -Url "/_api/BrandCenter/GetSiteThemes" `
    -Method Get `
    -ErrorAction Stop

$themes = @($response.themeData | Where-Object { $_.name -eq $themeName })
if ($themes.Count -ne 1) {
    throw "Expected one site theme named '$themeName'; found $($themes.Count)."
}
if ([string]::IsNullOrWhiteSpace($themes[0].themeJson)) {
    throw "Site theme '$themeName' has no theme definition."
}

$theme = $themes[0].themeJson | ConvertFrom-Json -ErrorAction Stop
$outputFolder = Join-Path $PSScriptRoot "Themes"
New-Item -Path $outputFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
$outputPath = Join-Path $outputFolder "$themeName.Theme.json"
$theme | ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $outputPath -Encoding utf8 -ErrorAction Stop
Write-Host "Exported site theme '$themeName' to '$outputPath'."
#endregion

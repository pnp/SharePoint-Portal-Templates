Import-Module PnP.PowerShell -Force

#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "span001" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "781d6ed3-0279-412e-af06-acfa99f57819" # The App Id from your App Registration for PnP.PowerShell
$themeName = "Solbound.Theme" # Must match the tenant theme name exactly
#endregion

$siteConnection = Connect-PnPOnline -ClientId $clientId -Url "https://$($tenant).sharepoint.com" -Interactive -ReturnConnection -ErrorAction Stop

#region Export Theme
$context = Get-PnPContext -Connection $siteConnection -ErrorAction Stop
$brandCenter = [Microsoft.SharePoint.Client.BrandCenter]::new($context)
$tenantThemes = $brandCenter.GetTenantThemes()
Invoke-PnPQuery -Connection $siteConnection -ErrorAction Stop
if ($null -eq $tenantThemes.Value) {
    throw 'SharePoint returned no tenant theme response.'
}

$themes = @($tenantThemes.Value.themeData | Where-Object { $_.name -eq $themeName })
if ($themes.Count -ne 1) {
    $availableThemes = @($tenantThemes.Value.themeData | ForEach-Object { $_.name })
    throw "Expected one tenant theme named '$themeName'; found $($themes.Count). Available tenant themes: $($availableThemes -join ', ')."
}
$themeJson = $themes[0].themeJson
if ([string]::IsNullOrWhiteSpace($themeJson)) {
    throw "Tenant theme '$themeName' has no theme definition."
}
$theme = ConvertFrom-Json -InputObject $themeJson -ErrorAction Stop
if ($null -eq $theme) {
    throw "Tenant theme '$themeName' contains a null theme definition."
}
$outputFolder = Join-Path $PSScriptRoot "Themes"
New-Item -Path $outputFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
$outputPath = Join-Path $outputFolder "$themeName.json"
$theme | ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $outputPath -Encoding utf8 -ErrorAction Stop
Write-Host "Exported tenant theme '$themeName' to '$outputPath'."
#endregion

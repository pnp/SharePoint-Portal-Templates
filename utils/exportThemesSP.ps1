[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ThemeName, # Must match the tenant theme name exactly, for example Solbound.Theme.

    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName ($ThemeName -replace '\.Theme$', '') -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

$siteConnection = Connect-PnPOnline -ClientId $ClientId -Url "https://$($Tenant).sharepoint.com" -Interactive -ReturnConnection -ErrorAction Stop

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

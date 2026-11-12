# Exports a named site-local theme without changing the site or tenant themes.
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The URL name of the source site; also used for the output file name.

    [Parameter(Mandatory)]
    [string]$ThemeName, # Must match the local theme name exactly.

    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force -ErrorAction Stop

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

$adminConnection = Connect-PnPOnline -ClientId $ClientId -Url "https://$($Tenant)-admin.sharepoint.com" -Interactive -ReturnConnection

$siteConnection = Connect-PnPOnline -Connection $adminConnection -Url "https://$($Tenant).sharepoint.com/sites/$SiteName" -ReturnConnection -ErrorAction Stop

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

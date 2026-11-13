[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SiteName, # The template name; used for output file and folder names.

    [string]$SourceSite, # The URL name of the source site. Omit to export from the tenant root site.
    [string]$Tenant,
    [string]$ClientId
)

Import-Module PnP.PowerShell -Force

# Source tenant settings come from utils\source.config.json, environment variables or parameters.
$source = & "$PSScriptRoot\Get-SourceConfig.ps1" -SiteName $SiteName -Tenant $Tenant -ClientId $ClientId
$Tenant = $source.Tenant
$ClientId = $source.ClientId

# region Export Resources
$siteUrl = "https://$($Tenant).sharepoint.com/"
if ($SourceSite) { $siteUrl += "sites/$($SourceSite)" }
$siteConnection = Connect-PnPOnline -ClientId $ClientId -Url $siteUrl -Interactive -ReturnConnection

$outputPath = ".\utils\Pages Metadata\$($SiteName).PagesMetadata.csv"

$pages = Get-PnPListItem -Connection $siteConnection -List "Site Pages" `
    -Fields "FileLeafRef", "Title", "CanvasContent1", "BannerImageUrl", "AuthorByline", "FieldValuesAsText"

$results = @()

foreach ($page in $pages) {

    $fileName = $page.FieldValues["FileLeafRef"]
    $title = $page.FieldValues["Title"]
    $dept = $page.FieldValues["ol_Department"]

    # --- BEST-EFFORT thumbnail extraction ---
    # Try BannerImageUrl first (most reliable)
    $thumbUrl = $page.FieldValues["BannerImageUrl"].Url

    # Fallback: look inside CanvasContent1 for image (VERY imperfect)
    if (-not $thumbUrl -and $page.FieldValues["CanvasContent1"]) {
        if ($page.FieldValues["CanvasContent1"] -match '"serverProcessedContent":({.*?})') {
            $thumbUrl = "INFERRED_FROM_CANVAS"
        }
    }

    # Normalize URL (important for cross-tenant)
    $isSharePointFile = $false
    if ($thumbUrl -and $thumbUrl.StartsWith("http")) {
        $uri = [System.Uri]$thumbUrl
        $isSharePointFile = $uri.Host -like '*.sharepoint.com'
        $thumbUrl = $uri.AbsolutePath
    }

    $results += [PSCustomObject]@{
        ID           = $page.Id
        PageName     = $fileName
        Title        = $title
        Department   = $dept
        ThumbnailUrl = $thumbUrl
    }

    # Download thumbnails stored in SharePoint. Anonymous requests return a sign-in page, so use the connection.
    if ($thumbUrl -and $isSharePointFile) {
        $fileName = [System.IO.Path]::GetFileName($thumbUrl)
        $folder = ".\utils\Pages Metadata\$($SiteName)\$($page.Id)"

        if (!(Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder | Out-Null
        }

        try {
            Get-PnPFile -Connection $siteConnection -Url ([System.Uri]::UnescapeDataString($thumbUrl)) -Path $folder -FileName $fileName -AsFile -Force -ErrorAction Stop
            Write-Host "Downloaded thumbnail for page '$title' to '$folder\$fileName'"
        }
        catch {
            Write-Warning "Failed to download thumbnail for page '$title' from '$thumbUrl': $_"
        }
    }
}



$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8 -Force
& "$PSScriptRoot\Remove-TenantIdentity.ps1" -Path $outputPath

Write-Host "Export complete: $outputPath"

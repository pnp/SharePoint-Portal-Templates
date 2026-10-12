Import-Module PnP.PowerShell -Force


#region Variables
# Set variables - CHANGE THESE TO MATCH YOUR ENVIRONMENT
$tenant = "m365x58285237" # Your tenant name, without the .onmicrosoft.com or .com suffix
$clientId = "2396d3c1-c4c2-445b-b514-835990c14dd0" # The App Id from your App Registration for PnP.PowerShell
$siteName = "Contoso" # The URL name for the site you want to update.
#endregion

# region Export Resources
$siteUrl = "https://$($tenant).sharepoint.com/sites/$($siteName)"
$siteConnection = Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Interactive -ReturnConnection

$outputPath = ".\utils\Pages Metadata\$($siteName).PagesMetadata.csv"

$pages = Get-PnPListItem -Connection $siteConnection -List "Site Pages" `
    -Fields "FileLeafRef", "Title", "Canv
    asContent1", "BannerImageUrl", "AuthorByline", "FieldValuesAsText", "ol_Department"

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
    # if ($thumbUrl -and $thumbUrl.StartsWith("http")) {
    #     $uri = [System.Uri]$thumbUrl
    #     $thumbUrl = $uri.AbsolutePath
    # }

    $results += [PSCustomObject]@{
        ID           = $page.Id
        PageName     = $fileName
        Title        = $title
        Department   = $dept
        ThumbnailUrl = $thumbUrl
    }

    # If the $thumbUrl isn't in stock images, download it to the folder Pages Metadata
    if ($thumbUrl -and $thumbUrl -ne "INFERRED_FROM_CANVAS") {
        $uri = [System.Uri]$thumbUrl
        $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)
        $folder = ".\utils\Pages Metadata\$($siteName)\$($page.Id)"
        $downloadPath = "$($folder)\$($fileName)"

        if (!(Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder | Out-Null
        }

        try {
            Invoke-WebRequest -Uri $thumbUrl -OutFile $downloadPath -ErrorAction Stop
            Write-Host "Downloaded thumbnail for page '$title' to '$downloadPath'"
        }
        catch {
            Write-Warning "Failed to download thumbnail for page '$title' from '$thumbUrl': $_"
        }
    }
}



$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8 -Force

Write-Host "Export complete: $outputPath"

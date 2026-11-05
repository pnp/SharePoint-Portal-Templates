#Requires -Version 7.4.6
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
Sets up the tenant Brand Center and imports branding assets from every template.
.DESCRIPTION
Requires a Global Administrator and a PnP.PowerShell app registration with
delegated SharePoint AllSites.FullControl permission. Existing fonts and font
packages are reused by name. Brand colors are added or updated by name.
Palette-based tenant themes are imported or updated by name.
Public CDN is required for fonts; enabling it requires explicit opt-in.
.EXAMPLE
.\utils\setupTenant.ps1 -Tenant contoso -ClientId <app-id> -EnablePublicCdn
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]*$')]
    [string]$Tenant,

    [Parameter(Mandatory)]
    [guid]$ClientId,

    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]*$')]
    [string]$BrandCenterSiteName = 'BrandGuide',

    [switch]$EnablePublicCdn
)

$ErrorActionPreference = 'Stop'
$templatesPath = Join-Path $PSScriptRoot '..\templates'
$adminUrl = "https://$Tenant-admin.sharepoint.com"
$adminConnection = Connect-PnPOnline -ClientId $ClientId -Url $adminUrl -Interactive -ReturnConnection
$config = Get-PnPBrandCenterConfig -Connection $adminConnection

if (!$config.IsPublicCdnEnabled -and !$EnablePublicCdn) {
    throw 'Brand fonts require Public CDN. Rerun with -EnablePublicCdn to consent to enabling it. Files in public CDN origins can be accessed anonymously.'
}

$brandCenterUrl = $config.SiteUrl
if (!$brandCenterUrl -and $config.OrgAssets.Url) {
    $brandCenterUrl = $config.OrgAssets.Url.DecodedUrl
}

if (!$brandCenterUrl) {
    $brandCenterUrl = "https://$Tenant.sharepoint.com/sites/$BrandCenterSiteName"
    $site = Get-PnPTenantSite -Connection $adminConnection -Filter "Url -eq '$brandCenterUrl'"
    if (!$site) {
        Write-Host "Creating Brand Center site at $brandCenterUrl..."
        New-PnPSite -Connection $adminConnection -Type CommunicationSite -Title 'Brand Guide' -Url $brandCenterUrl -Wait | Out-Null
    }
}

Write-Host "Connecting to Brand Center at $brandCenterUrl..."
$brandConnection = Connect-PnPOnline -ClientId $ClientId -Url $brandCenterUrl -Interactive -ReturnConnection

if (!$config.OrgAssets.Url -or !$config.OrgAssets.Url.DecodedUrl) {
    # Brand Center is anchored to the tenant's organization assets site.
    $library = Get-PnPList -Connection $brandConnection -Identity 'BrandAssets' -Includes RootFolder
    if (!$library) {
        New-PnPList -Connection $brandConnection -Title 'Brand Assets' -Url 'BrandAssets' -Template DocumentLibrary | Out-Null
        $library = Get-PnPList -Connection $brandConnection -Identity 'BrandAssets' -Includes RootFolder
    }

    $realm = Get-PnPAuthenticationRealm -Connection $brandConnection
    $visitors = Get-PnPGroup -Connection $brandConnection -AssociatedVisitorGroup
    Add-PnPGroupMember -Connection $brandConnection -Group $visitors.Id -LoginName "c:0-.f|rolemanager|spo-grid-all-users/$realm" | Out-Null
    Add-PnPOrgAssetsLibrary -Connection $adminConnection `
        -LibraryUrl ("https://$Tenant.sharepoint.com" + $library.RootFolder.ServerRelativeUrl) `
        -CdnType Public -DefaultOriginAdded $false | Out-Null
}

if (!$config.IsBrandCenterSiteFeatureEnabled) {
    Write-Host 'Enabling Brand Center...'
    Invoke-PnPSPRestMethod -Connection $adminConnection -Method Post `
        -Url '/_api/SPO.Tenant/EnsureBrandCenterFeature' | Out-Null
}

if (!$config.IsPublicCdnEnabled) {
    Invoke-PnPSPRestMethod -Connection $brandConnection -Method Post `
        -Url '/_api/BrandCenter/EnableBrandCenterPublicCdn' | Out-Null
}

foreach ($feature in 'EnsureBrandFontsLibraryFeature', 'EnsureBrandColorsListFeature') {
    Invoke-PnPSPRestMethod -Connection $brandConnection -Method Post `
        -Url "/_api/BrandCenter/$feature" | Out-Null
}

for ($attempt = 0; $attempt -lt 12; $attempt++) {
    $config = Get-PnPBrandCenterConfig -Connection $adminConnection
    if ($config.IsBrandCenterSiteFeatureEnabled -and $config.IsPublicCdnEnabled -and
        $config.BrandFontLibraryId -ne [guid]::Empty -and $config.BrandColorsListId -ne [guid]::Empty) {
        break
    }
    if ($attempt -eq 11) {
        throw 'Brand Center is not ready after one minute. Allow provisioning to finish, then rerun the script.'
    }
    Start-Sleep -Seconds 5
}

$fontsByName = @{}
foreach ($font in (Get-PnPListItem -Connection $brandConnection -List $config.BrandFontLibraryId -Fields FileLeafRef -PageSize 500)) {
    $fontsByName[$font.FieldValues.FileLeafRef] = $true
}
$packagesByName = @{}
foreach ($package in (Get-PnPBrandCenterFontPackage -Connection $brandConnection -Store Tenant)) {
    $packagesByName[$package.Title] = $true
}
$colorsByName = @{}
foreach ($color in (Get-PnPListItem -Connection $brandConnection -List $config.BrandColorsListId `
            -Fields '_SPColorTitle', '_SPColorCode', '_SPColorVisible' -PageSize 500)) {
    $colorsByName[$color.FieldValues['_SPColorTitle']] = $color
}

$tenantThemesByName = @{}
foreach ($tenantTheme in (Get-PnPTenantTheme -Connection $adminConnection)) {
    $tenantThemesByName[$tenantTheme.Name] = $true
}

foreach ($template in (Get-ChildItem -LiteralPath $templatesPath -Directory | Sort-Object Name)) {
    Write-Host "Setting up branding for $($template.Name)..."
    $themePath = Join-Path $template.FullName 'Theme'
    if (Test-Path -LiteralPath $themePath -PathType Container) {
        foreach ($file in (Get-ChildItem -LiteralPath $themePath -Filter '*.Theme.json' -File | Sort-Object Name)) {
            $theme = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($theme.Name)) {
                throw "Tenant theme '$($file.FullName)' must define Name."
            }

            if ($theme.Palette -and ($theme.PSObject.Properties['SecondaryColors'] -or
                    $theme.PSObject.Properties['DisplayMode'])) {
                if ($theme.IsInverted -isnot [bool]) {
                    throw "Modern tenant theme '$($file.FullName)' must define IsInverted as a Boolean."
                }
                $themeJson = ConvertTo-Json -InputObject $theme -Depth 20 -Compress
                $request = @{
                    name                = $theme.Name
                    themeJson           = $themeJson
                    shouldParseColorPair = $false
                } | ConvertTo-Json -Depth 20 -Compress
                $endpoint = if ($tenantThemesByName.ContainsKey($theme.Name)) {
                    'UpdateTenantThemeAdvanced'
                }
                else {
                    'AddTenantThemeAdvanced'
                }
                Write-Host "  Creating or updating tenant theme $($theme.Name)..."
                try {
                    Invoke-PnPSPRestMethod -Connection $adminConnection -Method Post `
                        -Url "/_api/thememanager/$endpoint" -Content ([string]$request) `
                        -ContentType 'application/json;odata=nometadata' -ErrorAction Stop | Out-Null
                }
                catch {
                    if ($endpoint -ne 'UpdateTenantThemeAdvanced' -or
                        $_.Exception.Message -notlike "*You can't change a theme between legacy and new formats.*") {
                        throw
                    }

                    Write-Warning "Tenant theme '$($theme.Name)' has a conflicting format; deleting and recreating it. If recreation fails, the theme will remain absent."
                    Remove-PnPTenantTheme -Connection $adminConnection -Identity $theme.Name -ErrorAction Stop
                    $tenantThemesByName.Remove($theme.Name)
                    Invoke-PnPSPRestMethod -Connection $adminConnection -Method Post `
                        -Url '/_api/thememanager/AddTenantThemeAdvanced' -Content ([string]$request) `
                        -ContentType 'application/json;odata=nometadata' -ErrorAction Stop | Out-Null
                }
            }
            elseif ($theme.Palette -and $theme.IsInverted -is [bool]) {
                $palette = @{}
                foreach ($property in $theme.Palette.PSObject.Properties) {
                    $palette[$property.Name] = $property.Value
                }
                if ($palette.Count -eq 0) {
                    throw "Tenant theme '$($file.FullName)' has an empty Palette."
                }

                Write-Host "  Creating or updating tenant palette theme $($theme.Name)..."
                Add-PnPTenantTheme -Connection $adminConnection -Identity $theme.Name `
                    -Palette $palette -IsInverted $theme.IsInverted -Overwrite | Out-Null
            }
            else {
                throw "Tenant theme '$($file.FullName)' must define a Palette and IsInverted."
            }
            $tenantThemesByName[$theme.Name] = $true
        }
    }

    $fontsPath = Join-Path $template.FullName 'Fonts'
    if (Test-Path -LiteralPath $fontsPath -PathType Container) {
        foreach ($font in (Get-ChildItem -LiteralPath $fontsPath -File | Where-Object { $_.Extension -in '.ttf', '.otf', '.woff', '.woff2' })) {
            if (!$fontsByName.ContainsKey($font.Name)) {
                Write-Host "  Uploading font $($font.Name)"
                Add-PnPBrandCenterFont -Connection $brandConnection -Path $font.FullName -Visible $true | Out-Null
                $fontsByName[$font.Name] = $true
            }
        }
    }
    else {
        Write-Warning "$($template.Name): no Fonts folder; skipping font uploads."
    }

    foreach ($folderName in 'Font Packages', 'FontPackages') {
        $packagesPath = Join-Path $template.FullName $folderName
        if (!(Test-Path -LiteralPath $packagesPath -PathType Container)) {
            continue
        }
        foreach ($file in (Get-ChildItem -LiteralPath $packagesPath -Filter '*.Fonts.json' -File)) {
            $package = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if ([string]::IsNullOrWhiteSpace($package.Title)) {
                throw "Font package export '$($file.FullName)' has no Title."
            }
            if ($packagesByName.ContainsKey($package.Title)) {
                continue
            }

            $packageJsonPath = Join-Path $packagesPath ($file.Name -replace '\.Fonts\.json$', '.PackageJson.json')
            $packageJson = if (Test-Path -LiteralPath $packageJsonPath -PathType Leaf) {
                Get-Content -LiteralPath $packageJsonPath -Raw
            }
            else {
                $package.PackageJson
            }
            $definition = $packageJson | ConvertFrom-Json
            if (!$definition.fontFaces -or !$definition.fontSlots) {
                throw "Font package '$($package.Title)' must define fontFaces and fontSlots."
            }
            foreach ($face in $definition.fontFaces) {
                if (!$face.path -or !$fontsByName.ContainsKey($face.path)) {
                    throw "Font package '$($package.Title)' references a missing font: '$($face.path)'."
                }
            }

            # Keep all exported faces and variable-font settings, which the PnP
            # package creation cmdlet cannot represent.
            $body = @{
                Title       = $package.Title
                Store       = 0
                PackageJson = $packageJson
                IsHidden    = [bool]$package.IsHidden
                IsValid     = $true
            } | ConvertTo-Json -Depth 20
            Write-Host "  Creating font package $($package.Title)"
            # Unwrap ConvertTo-Json output so PnP sends JSON, not PSObject metadata.
            Invoke-PnPSPRestMethod -Connection $brandConnection -Method Post -Url '/_api/FontPackages' `
                -Content ([string]$body) -ContentType 'application/json;odata=nometadata' | Out-Null
            $packagesByName[$package.Title] = $true
        }
    }

    $colorsPath = Join-Path $template.FullName 'Brand Colors'
    if (!(Test-Path -LiteralPath $colorsPath -PathType Container)) {
        Write-Warning "$($template.Name): no Brand Colors folder; skipping brand colors."
        continue
    }
    foreach ($file in (Get-ChildItem -LiteralPath $colorsPath -Filter '*.Colors.json' -File)) {
        foreach ($color in (Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json)) {
            $fields = $color.FieldValues
            $name = $fields._SPColorTitle
            if ([string]::IsNullOrWhiteSpace($name) -or $fields._SPColorCode -notmatch '^#[0-9a-fA-F]{6}$' -or
                $fields._SPColorVisible -isnot [bool]) {
                throw "Invalid brand color in '$($file.FullName)': '$name'."
            }
            $values = @{
                '_SPColorTitle'   = $name
                '_SPColorCode'    = $fields._SPColorCode
                '_SPColorVisible' = $fields._SPColorVisible
            }
            $existing = $colorsByName[$name]
            if ($existing) {
                if ($existing.FieldValues['_SPColorCode'] -ne $values['_SPColorCode'] -or
                    $existing.FieldValues['_SPColorVisible'] -ne $values['_SPColorVisible']) {
                    Write-Host "  Updating brand color $name"
                    $colorsByName[$name] = Set-PnPListItem -Connection $brandConnection `
                        -List $config.BrandColorsListId -Identity $existing.Id -Values $values
                }
            }
            else {
                Write-Host "  Creating brand color $name"
                $colorsByName[$name] = Add-PnPListItem -Connection $brandConnection `
                    -List $config.BrandColorsListId -Values $values
            }
        }
    }
}

Write-Host "Tenant branding setup complete. Brand Center: $brandCenterUrl"

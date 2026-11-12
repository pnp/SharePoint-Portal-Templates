<#
.SYNOPSIS
Removes source-tenant identity from exported data files so they can be committed.
.DESCRIPTION
Rewrites .json, .csv and .xml files in place (or returns sanitized text with -Text):
  - drops SharePoint Author, Editor, AppAuthor and AppEditor properties from JSON
  - turns https://<host>.sharepoint.com{site} into {site}
  - replaces *.sharepoint.com hosts (including -admin and -my) with contoso.sharepoint.com
  - replaces *.onmicrosoft.com domains with contoso.onmicrosoft.com
File encoding (including a UTF-8 BOM) and line endings are preserved.
Display names inside page content are not changed; review exports before committing.
.EXAMPLE
.\utils\Remove-TenantIdentity.ps1 -Path ".\utils\Brand Colors\Contoso.Colors.json"
.EXAMPLE
.\utils\Remove-TenantIdentity.ps1 -Path .\templates
#>
[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Path')]
    [string[]]$Path,

    [Parameter(Mandatory, ParameterSetName = 'Text')]
    [AllowEmptyString()]
    [string]$Text,

    [string]$PlaceholderTenant = 'contoso'
)

$ErrorActionPreference = 'Stop'
$jsonString = '"(?:[^"\\]|\\.)*"'
$identityProperty = "`"(?:Author|Editor|AppAuthor|AppEditor)`"\s*:\s*(?:\{(?:[^{}`"]|$jsonString)*\}|null|$jsonString)\s*,\s*"

function ConvertTo-SanitizedText([string]$Value, [bool]$IsJson) {
    if ($IsJson) {
        $Value = [regex]::Replace($Value, $identityProperty, '')
    }
    $Value = [regex]::Replace($Value, 'https?://[A-Za-z0-9][A-Za-z0-9-]*(?:-admin|-my)?\.sharepoint\.com(?=\{site\})', '', 'IgnoreCase')
    $Value = [regex]::Replace($Value, '(%2f)?[A-Za-z0-9][A-Za-z0-9-]*?(-admin|-my)?\.sharepoint\.com', "`${1}$PlaceholderTenant`${2}.sharepoint.com", 'IgnoreCase')
    $Value = [regex]::Replace($Value, '(?<![A-Za-z0-9-])[A-Za-z0-9][A-Za-z0-9-]*\.onmicrosoft\.com', "$PlaceholderTenant.onmicrosoft.com", 'IgnoreCase')
    $Value
}

if ($PSCmdlet.ParameterSetName -eq 'Text') {
    return ConvertTo-SanitizedText $Text $false
}

$extensions = '.json', '.csv', '.xml'
$files = foreach ($item in $Path) {
    if (Test-Path -LiteralPath $item -PathType Container) {
        Get-ChildItem -LiteralPath $item -Recurse -File | Where-Object { $_.Extension -in $extensions }
    }
    elseif (Test-Path -LiteralPath $item -PathType Leaf) {
        Get-Item -LiteralPath $item
    }
    else {
        throw "Path not found: $item"
    }
}

foreach ($file in $files) {
    if ($file.Extension -notin $extensions) { continue }
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $original = [Text.UTF8Encoding]::new($false).GetString($bytes, $(if ($hasBom) { 3 } else { 0 }), $bytes.Length - $(if ($hasBom) { 3 } else { 0 }))
    $isJson = $file.Extension -eq '.json'
    $clean = ConvertTo-SanitizedText $original $isJson
    if ($clean -ceq $original) { continue }

    if ($isJson) {
        try { $null = $clean | ConvertFrom-Json } catch { throw "Sanitizing '$($file.FullName)' produced invalid JSON: $($_.Exception.Message)" }
    }
    [IO.File]::WriteAllText($file.FullName, $clean, [Text.UTF8Encoding]::new($hasBom))
    Write-Host "Sanitized $($file.FullName)"
}

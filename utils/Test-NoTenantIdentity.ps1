<#
.SYNOPSIS
Fails if tracked files (and text files inside tracked zips) contain tenant names or app client IDs.
.DESCRIPTION
Flags:
  - any *.onmicrosoft.com domain other than contoso.onmicrosoft.com
  - any *.sharepoint.com host other than contoso, tenant, admin or similar placeholders
  - a GUID next to the word clientId, other than an all-zero placeholder
  - every line of the optional, git-ignored utils\denylist.txt (one string per line; use it for
    your own source tenant names and app IDs)
Run from anywhere inside the repo. CI runs it on every push and pull request.
.EXAMPLE
.\utils\Test-NoTenantIdentity.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
$textExtensions = '.ps1', '.md', '.json', '.csv', '.xml', '.txt', '.yml', '.yaml'
$ignoredPaths = 'utils/Test-NoTenantIdentity.ps1', 'utils/Remove-TenantIdentity.ps1', 'utils/source.config.sample.json'
$placeholderHosts = 'contoso', 'tenant', 'admin', 'my', 'yourtenant', 'your-tenant', 'example', 'mytenant', 'yourdomain'

$denylist = @()
$denylistPath = Join-Path $repoRoot 'utils/denylist.txt'
if (Test-Path -LiteralPath $denylistPath) {
    $denylist = Get-Content -LiteralPath $denylistPath | Where-Object { $_.Trim() -and !$_.StartsWith('#') } | ForEach-Object { $_.Trim() }
}

function Find-Identity([string]$Text) {
    foreach ($m in [regex]::Matches($Text, '(?<![A-Za-z0-9-])([A-Za-z0-9][A-Za-z0-9-]*)\.onmicrosoft\.com', 'IgnoreCase')) {
        if ($m.Groups[1].Value -notin $placeholderHosts) { $m.Value }
    }
    foreach ($m in [regex]::Matches($Text, '(?<![A-Za-z0-9-])([A-Za-z0-9][A-Za-z0-9-]*?)(?:-admin|-my)?\.sharepoint\.com', 'IgnoreCase')) {
        if ($m.Groups[1].Value -notin $placeholderHosts) { $m.Value }
    }
    foreach ($m in [regex]::Matches($Text, 'client[ _-]?id["''\s:=]{1,6}([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})', 'IgnoreCase')) {
        if ($m.Groups[1].Value -notmatch '^[0-]+$') { $m.Value }
    }
    foreach ($term in $denylist) {
        if ($Text.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) { "denylist: $term" }
    }
}

$findings = [System.Collections.Generic.List[string]]::new()
$files = git -C $repoRoot ls-files | Where-Object { $_ -notin $ignoredPaths }
foreach ($file in $files) {
    $full = Join-Path $repoRoot $file
    if (!(Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()

    if ($extension -in $textExtensions) {
        foreach ($hit in (Find-Identity ([IO.File]::ReadAllText($full)) | Select-Object -Unique)) {
            $findings.Add("${file}: $hit")
        }
    }
    elseif ($extension -eq '.zip') {
        $zip = [IO.Compression.ZipFile]::OpenRead($full)
        try {
            foreach ($entry in $zip.Entries) {
                if ([IO.Path]::GetExtension($entry.FullName).ToLowerInvariant() -notin $textExtensions) { continue }
                $reader = [IO.StreamReader]::new($entry.Open())
                try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
                foreach ($hit in (Find-Identity $content | Select-Object -Unique)) {
                    $findings.Add("${file}!$($entry.FullName): $hit")
                }
            }
        }
        finally { $zip.Dispose() }
    }
}

if ($findings.Count) {
    $findings | ForEach-Object { Write-Host $_ }
    Write-Error "Found $($findings.Count) tenant name or client ID reference(s) in tracked files. Run utils\Remove-TenantIdentity.ps1 on exported data, or replace the values with placeholders."
    exit 1
}
Write-Host 'No tenant names or client IDs found in tracked files.'

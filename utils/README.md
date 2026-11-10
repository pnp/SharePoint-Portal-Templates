# Repo maintenance scripts

The scripts in this folder are for maintaining this repo. They are not part of installing a template; people installing a template should follow that template's README.

## Set up tenant branding (`setupTenant.ps1`)

Run [setupTenant.ps1](./setupTenant.ps1) to create or enable the tenant Brand Center and import the templates' fonts, font packages, and brand colors.

Requirements: PowerShell 7.4.6 or later, a compatible PnP.PowerShell module, a PnP Entra app registration with delegated SharePoint `AllSites.FullControl` permission, and a Global Administrator account with access to the Brand Center.

```powershell
.\utils\setupTenant.ps1 -Tenant "contoso" -ClientId "<your-app-id>" -EnablePublicCdn
```

`-EnablePublicCdn` explicitly consents to enabling Public CDN, which is required for brand fonts. Files in public CDN origins can be accessed anonymously. Omit the switch if Public CDN is already enabled.

The script reuses the existing Brand Center or organization assets site. Otherwise, it creates `/sites/BrandGuide` (override with `-BrandCenterSiteName`), registers a new Brand Assets library, and gives Everyone except external users visitor access. Existing fonts and font packages are reused by filename and exported title; colors are added or updated by name. Package imports use `*.Fonts.json` from `Font Packages` (or `FontPackages`), preferring a matching `*.PackageJson.json` for the package definition. Exported IDs and audit metadata are not copied. Missing font and color folders are reported and skipped. This does not create per-site themes from each template or apply font packages to individual sites; follow each site's instructions for those steps. A tenant theme in a template's `Theme` folder is created or updated by name. Full palette-based modern theme definitions with `secondaryColors` or `displayMode` are imported through SharePoint's advanced theme endpoint. If a modern theme update fails because the existing theme has a conflicting format, the existing theme is deleted and recreated under the same name. If recreation fails, the script stops and the theme remains absent. Legacy `Palette` themes are imported with PnP.PowerShell. ColorPairs-only themes are not supported and fail validation. Importing a theme makes it available tenant-wide but does not apply it to a site. CDN changes may take time to propagate.

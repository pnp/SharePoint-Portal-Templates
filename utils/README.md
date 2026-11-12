# Repo maintenance scripts

The scripts in this folder are for maintaining this repo. They are not part of installing a template; people installing a template should follow that template's README.

## Source tenant and destination tenant

The repo keeps the two tenants separate so no tenant names or client IDs are committed.

- **Destination tenant:** the tenant where someone installs a template. `_setupPnP.PowerShell.ps1`, `setupTenant.ps1` and each template's `ApplyPnPProvisioningTemplate.ps1` take `-Tenant` and `-ClientId` as parameters. They have no defaults.
- **Source tenant:** the tenant where maintainers build the template sites. The `export*.ps1` scripts and each template's `Get-PnPProvisioningTemplate.ps1` read from it. Only maintainers need it.

### Configure the source tenant (maintainers)

Copy [source.config.sample.json](./source.config.sample.json) to `utils\source.config.json` and fill in your values. The file is git-ignored.

```json
{
  "Tenant": "your-source-tenant",
  "ClientId": "<your-app-id>",
  "Sites": {
    "Credimus": { "Tenant": "another-source-tenant", "ClientId": "<another-app-id>" }
  }
}
```

[Get-SourceConfig.ps1](./Get-SourceConfig.ps1) resolves each value in this order: the `-Tenant` / `-ClientId` parameters, the `PNP_SOURCE_TENANT` / `PNP_SOURCE_CLIENT_ID` environment variables, the `Sites.<name>` entry that matches the template or site name, then the top-level values. The export scripts take the template name as `-SiteName`:

```powershell
.\utils\exportBrandColors.ps1 -SiteName Contoso
```

Export scripts run [Remove-TenantIdentity.ps1](./Remove-TenantIdentity.ps1) on what they write. It drops author and editor fields, turns `https://<tenant>.sharepoint.com{site}` into `{site}`, and replaces tenant hosts and domains with `contoso`. Page content can still contain display names, so review exports before you commit them.

### Check before you commit

```powershell
.\utils\Test-NoTenantIdentity.ps1
```

This fails if any tracked file, or any text file inside a tracked zip, contains a `*.onmicrosoft.com` or `*.sharepoint.com` name other than a `contoso` placeholder, or a client ID. Add your own source tenant names and app IDs, one per line, to the git-ignored `utils\denylist.txt` to catch them too. A GitHub Actions workflow runs the same check on every push and pull request.

When you rebuild a template zip, include everything in the template folder except the zip itself, `SiteAssets-Cleanup-Report.md` and `Get-PnPProvisioningTemplate.ps1`. The last one is a maintainer export script.

## Register the PnP app (`_setupPnP.PowerShell.ps1`)

Run [_setupPnP.PowerShell.ps1](./_setupPnP.PowerShell.ps1) once per tenant to register the Entra ID app that PnP.PowerShell uses for interactive sign-in. The app's client ID is what the other scripts take as `-ClientId`.

Requirements: the [PnP.PowerShell](https://pnp.github.io/powershell/) module installed, and an account that can register apps and grant admin consent in the tenant.

1. Run the script with your tenant name, without the `.onmicrosoft.com` or `.com` suffix (for example, `contoso`):

   ```powershell
   .\utils\_setupPnP.PowerShell.ps1 -Tenant contoso
   ```

2. Sign in and accept the permission and consent prompts when asked. The script registers an app named `PnP.PowerShell` in your tenant.
3. Copy the client ID (app ID) the script prints. Pass it to scripts such as `setupTenant.ps1` with `-ClientId`, or to `Connect-PnPOnline -Interactive -ClientId <your-app-id>`.

If you lose the client ID, find the `PnP.PowerShell` app in Microsoft Entra ID under **App registrations**. The script requests delegated SharePoint `AllSites.FullControl` by default, which `setupTenant.ps1` needs. Confirm it under **API permissions** and grant admin consent if needed.

## Set up tenant branding (`setupTenant.ps1`)

Run [setupTenant.ps1](./setupTenant.ps1) to create or enable the tenant Brand Center and import the templates' fonts, font packages, and brand colors.

Requirements: PowerShell 7.4.6 or later, a compatible PnP.PowerShell module, a PnP Entra app registration with delegated SharePoint `AllSites.FullControl` permission, and a Global Administrator account with access to the Brand Center.

```powershell
.\utils\setupTenant.ps1 -Tenant "contoso" -ClientId "<your-app-id>" -EnablePublicCdn
```

`-EnablePublicCdn` explicitly consents to enabling Public CDN for the tenant (without the default origins), which is required for brand fonts and for registering the organization assets library. Files in public CDN origins can be accessed anonymously. Omit the switch if Public CDN is already enabled.

The script reuses the existing Brand Center or organization assets site. Otherwise, it creates `/sites/BrandGuide` (override with `-BrandCenterSiteName`), registers a new Brand Assets library, and gives Everyone except external users visitor access. Existing fonts and font packages are reused by filename and exported title; colors are added or updated by name. Package imports use `*.Fonts.json` from `Font Packages`, preferring a matching `*.PackageJson.json` for the package definition. Exported IDs and audit metadata are not copied. Missing font and color folders are reported and skipped. This does not create per-site themes from each template or apply font packages to individual sites; follow each site's instructions for those steps. A tenant theme in a template's `Theme` folder is created or updated by name. Full palette-based modern theme definitions with `secondaryColors` or `displayMode` are imported through SharePoint's advanced theme endpoint. If a modern theme update fails because the existing theme has a conflicting format, the existing theme is deleted and recreated under the same name. If recreation fails, the script stops and the theme remains absent. Legacy `Palette` themes are imported with PnP.PowerShell. ColorPairs-only themes are not supported and fail validation. Importing a theme makes it available tenant-wide but does not apply it to a site. CDN changes may take time to propagate.

What `setupTenant.ps1` imports for each template:

| Template | Tenant theme | Fonts uploaded | Font package | Brand colors |
|---|---|---|---|---|
| Contoso | `Contoso.Theme` (advanced) | 28 Aptos font files (`.ttf`) | `Contoso.Fonts` | `Contoso.Blue`, `Contoso.Peach` |
| Credimus | `Credimus.Theme` (advanced) | 4 files: DM Sans and Playfair variable fonts (`.ttf`) | `Credimus.Fonts` | `Credimus.DeepEmerald`, `Credimus.DarkTeal`, `Credimus.CyanEdge`, `Credimus.Carbon` |
| Solbound | `Solbound.Theme` (advanced) | 36 files: Barlow and Exo 2 (`.woff2`) | `Solbound.Fonts` | `Solbound.Yellow`, `Solbound.Blue`, `Solbound.Orange`, `Solbound.Neutral` |
| Woodgrove | `Woodgrove.Theme` (advanced) | None. Uses a Microsoft-provided font. | None | `Woodgrove.Midnight`, `Woodgrove.Cyan`, `Woodgrove.Teal`, `Woodgrove.Neutral` |

Themes marked advanced are imported through SharePoint's advanced theme endpoint. Fonts and font packages that already exist in the tenant are skipped, and brand colors that already exist are updated by name.

When the script finishes, it prints the Brand Center app link: `<brand center site>/_layouts/15/BrandCenter.aspx`. Open it directly to manage fonts, font packages and colors. The Brand Center app link is also under **Settings > Org settings > Brand center** in the Microsoft 365 admin center. If the Brand center entry or the admin center page doesn't load right after setup, restart the browser or use a private window.
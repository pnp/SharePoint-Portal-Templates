# Change Log

## Version 1.1.0 - Contoso and Woodgrove sites

- Added the Contoso and Woodgrove sites, each with a README, a provisioning script, ACE definitions and a ZIP file. Each ZIP is under GitHub's 100 MiB file limit.
- Removed unused and duplicate images from the Contoso and Woodgrove SiteAssets (about 532 MiB for Contoso and 36 MiB for Woodgrove), then compressed the remaining JPEG and PNG files. Compression took SiteAssets from 210 MiB to 72.8 MiB for Contoso and from 185 MiB to 57.2 MiB for Woodgrove.
- Contoso is self-contained: it no longer references any other template.
- Contoso template fixes:
  - Event banners, news thumbnails and the footer logo now use `{site}` paths, so they load on any site.
  - The second Events web part reads the site's own Events list.
  - The Viva Connections dashboard cards use Card Designer cards.
  - The font package is named `Contoso.Fonts`.
- Woodgrove template fixes:
  - The footer no longer contains attributes the PnP schema rejects, which caused "Template is not valid" when applying the template.
  - The header uses the Extended layout so the header background image appears, and the image is set with a server-relative path.
  - The color table in the README matches the Woodgrove theme (`Woodgrove.Theme`).
  - Woodgrove uses a Microsoft-provided font, so it has no font package.
- Theme and font steps are manual README steps for Contoso and Woodgrove. The provisioning scripts don't apply the theme.
- Added the README screenshots for Contoso and Woodgrove as JPG files.
- Corrected README and script typos, links and image paths, and removed claims about steps the scripts don't perform.
- The main README no longer mentions the maintenance scripts. They are documented in `utils/README.md`.

## Version 1.0.0 - Initial release

- Initial release with documentation and PowerShell script to apply the provisioning template
- Credimus and Solbound sites

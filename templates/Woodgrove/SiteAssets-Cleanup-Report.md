# Woodgrove SiteAssets cleanup report

Scope: `templates/Woodgrove/PnPProvisioning/SiteAssets`, with the only XML change made in [PnP-Provisioning-Clean.xml](PnPProvisioning/PnP-Provisioning-Clean.xml). `PnP-Provisioning.xml` is kept as the raw export from the source site and was **not** modified. The scratch file `PnP-Provisioning-test.xml` was later deleted. Nothing was committed by this work. The last section covers the later changes.

## Result

| | Before | After |
|---|---:|---:|
| Files in SiteAssets | 32 | 30 |
| Size on disk | 221.5 MiB | 185.0 MiB (**−36.5 MiB**) |
| `<pnp:File>` declarations in Clean XML | 51 | 47 |

Woodgrove was already lean: 28 of its 32 files were referenced by the Clean XML or its scripts/CSVs. The only meaningful saving was one duplicate hero image.

## Duplicates replaced

Both pairs were verified byte-identical (SHA-256) before any change.

| Removed file | References now point to | Reference edits |
|---|---|---|
| `SitePages/Home/1372799161-GettyImages-2225209600.jpg` (36.48 MiB) | `SitePages/Home/1014433986-GettyImages-2225209600.jpg` | 3, in the Home hero's `originalImageMetadata` (`fileName`, `uniqueId`, `url`) |
| `SitePages/Home/1579592023-Logo-top.png` (0.04 MiB) | `SitePages/Home/1754349987-Logo-top.png` | 4, in the Home image web part (`fileName`, `uniqueId`, `imageSource`, `uniqueid`) |

The two cropped hero images (`…_1788373331821.jpg` and `…_1788373345909.jpg`) are different files and were kept. Each still shows its own crop. Only the pointer to the full-size original changed, so both crops now point to the same original, which is the same photo. Both Logo-top web parts now use the same file, which is also the one the Pages Metadata CSV references.

## Malformed banner fixed

One value was malformed: the Event(2) `BannerImageUrl` read `{site}//_layouts/15/getpreview.ashx?path={site}/SiteAssets/…`. `{site}` is already the web's server-relative URL, so the doubled slash was a leftover of the root-site export problem. It is now `{site}/_layouts/15/getpreview.ashx?path={site}/SiteAssets/…`. The other banner values in this file were already in the correct form.

## Not removed

| File | Why kept |
|---|---|
| `SitePages/Event(1)/98868-GettyImages-2166211751.jpg` (18.84 MiB) | Not used by the Clean XML but **referenced by `PnP-Provisioning.xml`**. Largest remaining candidate if you confirm that XML is obsolete. |
| `__extendedFooterBackgroundImage____extendedFooterBackgroundImage__Frame 2147225511.png` (0.97 MiB), `__extendedFooterBackgroundImage__BG3.png` (0.25 MiB), `__extendedHeaderBackgroundImage____extendedHeaderBackgroundImage__BG6.png` (0.04 MiB) | Unreferenced duplicates of other files, but these are SharePoint branding names (`__extended…`), so they were kept for doubt. The doubled-prefix names look like artifacts and are probably safe to delete. |
| `__sitelogo__LogoW.png` and `__extendedHeaderBackgroundImage__LogoW.png` | Identical, but `ApplyPnPProvisioningTemplate.ps1` names both explicitly (the script's logo paths were not changed). |
| `__extendedHeaderBackgroundImage__BG6.png` and `Home/370988152-BG6.png` | Identical, but one is the header background named in the apply script and the other is a page section background. |
| `Home/883649571-BG3.png` and `__extendedFooterBackgroundImage__BG3.png` | Identical, but one is a page asset and the other a footer-branding asset. |

I also left the empty folder definitions already in the Site Assets list (for example `TopicHome` and the two `CRDM-closes…`/`Q1-AML…` folders) alone, because nothing I removed emptied a folder.

## Verification

- Clean XML is well-formed, with BOM and CRLF line endings preserved.
- All 30 files on disk are declared in the Clean XML, and every declaration has a file.
- Re-running the reference analysis found no references left to the two removed files in the Clean XML, and no malformed banner values.
- **Not tested:** applying the template to a tenant.

## Image compression (applied after the cleanup)

To bring the ZIP under GitHub's 100 MiB limit, the 20 images of 250 KiB or more were recompressed **in place** with unchanged file names, extensions and pixel dimensions, so no XML or reference changes were needed.

- **JPEG (11 files):** mozjpeg quality 85, 4:2:0, progressive, EXIF stripped. Measured quality against the originals was 33.8–45.0 dB PSNR, with no visible difference at 100% zoom apart from slightly smoothed grain.
- **PNG (7 files recompressed, 2 left unchanged):** lossless repack, dropping the alpha channel where it was fully opaque. A pixel comparison confirmed every recompressed PNG is **pixel-identical** to the original. `BG2.png` and `BG5.png` had no meaningful gain and were left as is.
- **Result:** SiteAssets went from 185.0 MiB to 57.2 MiB. A test ZIP of the whole Woodgrove folder, built in a temp location, is **56.7 MiB**.
- **Originals:** tracked in git (`git restore` brings them back) and also backed up at `C:\Users\mdent\.copilot\session-state\06350047-0f99-4053-824b-b6e4f1c7467c\files\imgwork\originals\Woodgrove`. Per-file sizes and checks are in `imgwork\compress-Woodgrove.csv` in the same folder.

## Heads-up: the raw export XML

Because only the Clean XML was updated, **`PnP-Provisioning.xml` still references the two removed files** (13 references) and still declares them. It is kept as the raw export from the source site and is not used by `ApplyPnPProvisioningTemplate.ps1`, which uses the Clean XML, so the normal path is unaffected. To use it again, restore the files (below) or regenerate it with `Get-PnPProvisioningTemplate.ps1`.

## Undo

Nothing was permanently deleted. The two files are tracked in git and are also in
`C:\Users\mdent\.copilot\session-state\06350047-0f99-4053-824b-b6e4f1c7467c\files\woodgrove-cleanup-quarantine`
together with the original Clean XML (`xml-original\`). To restore, copy the files back into `PnPProvisioning\SiteAssets\SitePages\Home` and the original XML back into `PnPProvisioning`, or run `git restore` on the changed paths. (The backup and quarantine folders are local to the machine that ran this work, not part of the repo.)

## Later changes (audit of the whole Woodgrove folder)

Audit of the whole Woodgrove folder (README, scripts, ACEs, template, assets and ZIP). Template fixes were already in the Clean XML; the fixes below are in the script, README and export script.

**Script (`ApplyPnPProvisioningTemplate.ps1`)**
- The ACE path now matches the folder case (`ACEs/Woodgrove.ACEs.csv`, previously `ACES/…`, which fails on case-sensitive systems).
- Removed a stray trailing backtick after `-CardSize $ace.CardSize`, an unused `$siteName` variable and an empty `# Resources` stub (Woodgrove has no Resources web part, and `Resources/Woodgrove.Resources.csv` holds an empty configuration).

**Export script (`Get-PnPProvisioningTemplate.ps1`)**
- After `PnP-Provisioning-test.xml` was deleted and the export repointed to `PnP-Provisioning.xml`, one reference was missed: `$sourcePath` still copied from the deleted file. It now copies from `PnP-Provisioning.xml`.

**README**
- Typos ("this **if** you have set it up", "ACEs") and the malformed colors-table row were fixed, and "Ready to provision…" now follows the download and extract steps.
- The Resources claims were removed (the script does not set up Resources, and the site has no Resources web part).
- The 6 image links are lowercase (`./media/woodgrove-*.jpg`). The 6 screenshots were added as PNGs and converted to JPG (1.98 → 0.56 MiB; originals backed up locally). The font screenshot is now `woodgrove-apply-font.jpg`, because Woodgrove uses a Microsoft-provided font and has no font package.
- The ZIP description no longer claims it contains fonts. The colors table uses the theme's colors.

**Header (found on the MARCTEST12 test)**
- The header background image only shows with the **Extended** header layout. `-HeaderLayout` was `Standard` (and the raw export says `Compact`, so neither showed it). The script and the Clean XML `<pnp:Header Layout>` now use `Extended`, and the script passes the image as a server-relative path (`/sites/<site>/SiteAssets/…`).
- Not carried by the template: the source site's footer settings (background image, overlay, alignment). They would need to be set through the property bag in the script.

**Last-pass checks (all passed)**
- Schema validation: the Clean XML initially failed PnP's schema check ("Template is not valid" when applying). The `<pnp:Footer>` element carried two attributes the PnP 2022/09 schema does not declare (`Alignment` and `backgroundImageUrl`, added in an earlier commit; the raw export has neither). They were removed, and the file now validates (checked with PnP.Framework 1.21.76, the same validator `Invoke-PnPSiteTemplate` uses). The footer background image files stay in `SiteAssets` but are not referenced.
- Clean XML is well-formed; all 47 `File` entries exist on disk and nothing on disk is unlisted.
- All 51 `SiteAssets` references (pages, web parts, events, thumbnails, ACE image, script) resolve to a `File` entry. No mangled `{site}` tokens, no root-relative paths, no tenant host names, no other-template names.
- The script's logo now uses `__sitelogo__LogoW.png`, as on the live site (the `__extendedHeaderBackgroundImage__LogoW.png` file is byte-identical, so nothing changes visually). `$siteUrl` is set to `MARCTEST12`.
- README links all resolve, and "Woodbridge" appears nowhere in the repo.
- Four export-artifact duplicates remain in `SiteAssets` root (`____extended…` copies of the footer image and BG6, and the two `LogoW` copies, about 0.9 MiB). They are harmless and were left as is.

**Checked and fine**
- Clean XML: no root-relative thumbnails, no mangled `{site}` tokens, no other-site references, every declared file exists, and the 3 CDN thumbnails return 200. The Home page has no Events web part, so no date range applies.
- Folder contents: no references to other templates apart from `Pages Metadata` and the raw `PnP-Provisioning.xml` (source-tenant host names, neither used by the script).
- The live `/sites/Woodgrove` site (provisioned earlier) has working thumbnails, logo and 5 dashboard cards.

**Open**
- **Theme name and colors:** resolved. The theme is now named **Woodgrove.Theme** and the README color table lists the theme's colors (`#0D2C35`, `#06B6D4`, `#009184`, `#EDEDED`).
- **Screenshots:** resolved.
- **Other-tenant host names in `Pages Metadata` and the raw XML, and the placeholder `adaptivecards.io` ACE links:** left as is, by decision.
- **Test provision:** not yet run on a fresh site (planned: MARCTEST12).

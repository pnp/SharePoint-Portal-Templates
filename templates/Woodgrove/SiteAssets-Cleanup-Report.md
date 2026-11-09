# Woodgrove SiteAssets cleanup report

Scope: `templates/Woodgrove/PnPProvisioning/SiteAssets`, with the only XML change made in [PnP-Provisioning-Clean.xml](PnPProvisioning/PnP-Provisioning-Clean.xml). `PnP-Provisioning.xml` and `PnP-Provisioning-test.xml` were **not** modified. Nothing was committed.

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
| `__sitelogo__LogoW.png` and `__extendedHeaderBackgroundImage__LogoW.png` | Identical, but `ApplyPnPProvisioningTemplate.ps1` names both explicitly (the script was not changed). |
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

## Heads-up: the other two XML files

Because only the Clean XML was updated, **`PnP-Provisioning.xml` and `PnP-Provisioning-test.xml` now reference the two removed files** (13 references each) and still declare them. Applying either of those would fail on the missing files. `ApplyPnPProvisioningTemplate.ps1` uses the Clean XML, so the normal path is unaffected. To use the other XMLs again, restore the files (below) or regenerate those XMLs.

## Undo

Nothing was permanently deleted. The two files are tracked in git and are also in
`C:\Users\mdent\.copilot\session-state\06350047-0f99-4053-824b-b6e4f1c7467c\files\woodgrove-cleanup-quarantine`
together with the original Clean XML (`xml-original\`). To restore, copy the files back into `PnPProvisioning\SiteAssets\SitePages\Home` and the original XML back into `PnPProvisioning`, or run `git restore` on the changed paths.

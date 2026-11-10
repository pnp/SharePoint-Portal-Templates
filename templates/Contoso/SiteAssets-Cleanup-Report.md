# Contoso SiteAssets cleanup report

Scope: `templates/Contoso/PnPProvisioning/SiteAssets` and the two template files that declare those assets, [PnP-Provisioning-Clean.xml](PnPProvisioning/PnP-Provisioning-Clean.xml) (used by `ApplyPnPProvisioningTemplate.ps1`) and [PnP-Provisioning.xml](PnPProvisioning/PnP-Provisioning.xml). The cleanup edited both XMLs; every later fix was made to the Clean XML only, because `PnP-Provisioning.xml` is kept as the raw export from the source site. Nothing was committed by this work. The last section, **Later changes and live verification**, covers what was done after the cleanup.

## Result

| | Before | After | Change |
|---|---:|---:|---:|
| Files in SiteAssets | 172 | 72 | −100 |
| Size on disk | 742.9 MiB | 210.3 MiB | **−532.5 MiB (−72%)** |
| Size on disk after image compression | | 72.8 MiB | **−670.1 MiB (−90%)** |
| `<pnp:File>` declarations per XML | 191 | 90 | −101 (one file was declared twice) |
| Site Assets folder definitions removed per XML | | 20 | |

| Removed because | Files | Size |
|---|---:|---:|
| Not referenced anywhere in the template | 97 | 494.2 MiB |
| Byte-identical duplicate of a file that is referenced (references repointed) | 3 | 38.4 MiB |

## How "used" was decided

A file counted as used if its path or file name appeared **outside the `<pnp:Files>` upload list** in either XML (page canvas JSON, page `ThumbnailUrl`/header images, Events rows, WebSettings, Footer, Navigation), or in any `.ps1`, `.csv`, `.json` or `.md` in the Contoso folder (including `Resources`, `ACEs`, `Pages Metadata`). Matching handled `{site}` tokens, URL-encoding (`%2F`, `%20`), HTML entities and JSON escapes, and required a file-name boundary so `3.png` is not "found" inside `33.png`. No page uses raw GUID image references, so path matching is complete for page content. The 15 pages in the XML are identical to the committed template.

Anything with doubt was kept (see [Kept because of doubt](#kept-because-of-doubt)).

## Duplicates replaced

All were verified byte-identical (SHA-256) before any change. References were edited in **both** XML files.

| Removed file | References now point to | Reference edits (per XML) |
|---|---|---|
| `SitePages/Miriam-Graham,-Contoso's-new-Chief-Marketing-Officer/71656-GettyImages-2166211751.jpg` (18.84 MiB) | `SitePages/Q1-2024-Peak-performance-report-efficiency-rankings-by-company-installers_29757474/GettyImages-2166211751.jpg` | 3: title-area `uniqueId` ×2 and `imageSource` in page *Miriam-Graham,-Contoso's-new-Chief-Marketing-Officer.aspx* |
| `SitePages/Event(17)/35025-GettyImages-1681129349.jpg` (12.64 MiB) | `SitePages/Event(11)/62013-GettyImages-1681129349.jpg` | 3: `BannerUrl` ×2 and preview URL on the event **Company, Q1 All Hands meeting** |
| `SitePages/Page/GettyImages-1850142671.jpg` (6.88 MiB) | `SitePages/Page/2034430082-GettyImages-1850142671.jpg` | 1: page `ThumbnailUrl` of *Arizona's solar wave initiative…* (the section background already used the retained copy) |

Only the file path was swapped in the Event rows. Their `Id=` and `listId=` query parameters still hold the original file's GUIDs; those already do not match any other tenant. This is the one replacement with a slight residual risk, so check that event's banner after provisioning.

Duplicates of referenced files that were themselves unreferenced were simply removed, with no reference changes needed. This covers `Home/3.png`–`8.png` (the references use `33.png`–`88.png`, which were kept), Home `874225332-GettyImages-2223895987.jpg`, Event `(1)`, `(2)`, `(3)`, `(7)`, `(9)`, `(10)`, `(14)`–`(16)` and `Page/1142074377-…`/`3912178919-…`.

## Removed: unreferenced files, by folder

| Folder under SiteAssets | Files | MiB |
|---|---:|---:|
| `SitePages/Home` | 26 | 272.62 |
| `SitePages/Page` (2 unreferenced + the duplicate above) | 3 | 39.20 |
| `Images` | 23 | 33.39 |
| `SitePages/Miriam-Graham,-Contoso's-new-Chief-Marketing-Officer` (duplicate above) | 1 | 18.84 |
| `SitePages/Event`, `Event(1)`, `Event(7)` | 3 | 48.48 |
| `SitePages/Event(3)`, `(10)`, `(14)`, `(15)`, `(16)` | 5 | 71.10 |
| `SitePages/Event(2)`, `(9)` and `(17)` (duplicate above) | 3 | 37.92 |
| `SitePages/TheLanding` | 15 | 6.40 |
| `SitePages/1` | 20 | 2.48 |
| `SitePages/Presentations-in-a-hybrid-working-world` | 1 | 2.14 |

Largest individual files (≥ 20 MiB): `Home/…-Background-2.png` ×3 and `Home/…-hero-background.png` ×2 (each 28.7–29.5 MiB, leftover originals of section backgrounds), `Images/A Woman Doing a Business Presentation.mp4` (25.4 MiB), and their timestamp-suffixed crops (21.9–25.0 MiB each). The page-level images that Home actually uses (`2613382694-Background-2.png`, `2834290595-Frame-2147238931*.png`, `306934070-GettyImages-2223895987.jpg`, …) were kept.

<details><summary>Smaller removed files (64 files, 11.7 MiB)</summary>

- **Images (19):** cafe-40.jpg, cafemenu.jpeg, ceo-connections.jpg, chicken.jpeg, dueSoon.png, headspace.jpg, health-check-small.jpg, health-check.jpg, hrsupport.png, ic-dining.png, kudos-high.png, kudos-small.png, kudos.png, learning-1.jpg, shuttle-large.png, steak.jpeg, tofu.jpeg, training-small.png, training.png
- **SitePages/1 (20):** 1194575696thumbnail.jpg, 1849088311a1bdd325-6fc1-4303-945d-1d313e2e70ac.jpg, 2180886392thumbnail (1).jpg, 3965648127-f3bde309-bb95-4e38-9bcb-a52f34126e24.jpg, 536358505166928e7-45e0-41f7-8aba-7d73ae66c6f8.jpg, calltoaction-bg.jpeg, CC-01.jpg, CC-02.jpg, CC-03-contoso.jpg, CC-03.jpg, CC-04.jpg, hero-01.jpg … hero-04.jpg, ic-benefits.png, ic-timetracking.png, ic-travel.png, purpose-vision.jpg, quicklinks-covid-large.jpeg
- **SitePages/Home (11):** 11.svg, 3.png, 4.png, 5.png, 6.png, 7.png, 8.png, Stack1.png, 3402492354-Frame-2147238928.png, 874225332-GettyImages-2223895987_1785454788342.jpg, …_1785454940848.jpg
- **SitePages/TheLanding (14):** 3col_* images (6), 99802443778008countdowntimer_2a.png, carlos.jpg, ic-401k.png, ic-health.png, mark8roadmap.jpg, privacy.jpg, quadcopter.jpg, townhall.jpg

</details>

## Kept because of doubt

These are unreferenced by the template but were kept because something outside it may use them. They total about 2.8 MiB.

| Files | Why kept |
|---|---|
| 9 `__*` files at the SiteAssets root (`__sitelogo__*`, `__rectSitelogo__*`, `__globalNavigationLogo__*`, `__extendedHeaderBackgroundImage__*`) | SharePoint's site-logo/header settings use these names, and `ApplyPnPProvisioningTemplate.ps1` sets `__sitelogo__Logo.png` and `__extendedHeaderBackgroundImage__DEFAULT_CHROME_BG_IMAGE_NAME.png` (the script originally omitted the `.png`; see the last section). `__extendedHeaderBackgroundImage__Frame 2147238928.png` (2.53 MiB) is the only sizeable one; no file references it, but it may be the header background currently set in the source site. |
| 18 files in `Icons/` (`ic-*.png`, ≤ 4 KB each) | Viva-style card icons. Nothing references them, but they are negligible in size. |
| 5 root-level auto-named logos (`LogoChat_…png`, `TSLogo_…svg`, `icon_…svg`, `ukgIcon_…svg`, `xm_logomark_…svg`) | Names look like Viva Connections/app icons created by SharePoint. |
| `SitePages/Dashboard/dashboard-news.jpg` | Matched by file name only (see finding 2; left as is by decision). |

Duplicates left among these: `__rectSitelogo__Logo.png` = `__sitelogo__Logo.png`, and the three `Frame 2147238891` branding files are identical to each other.

## Verification

- 72 files remain; 100 are in quarantine; none are in both.
- Both XMLs are well-formed, with original BOM and line endings preserved.
- Every remaining `<pnp:File>` declaration has a file on disk, and every file on disk is declared.
- Re-running the reference analysis found no unreferenced files outside the kept-for-doubt groups, and no new broken references (one pre-existing, below).
- At the time of the cleanup, `ApplyPnPProvisioningTemplate.ps1`, `Resources`, `ACEs` and `Pages Metadata` were not modified (later edits are listed in the last section).
- The template was later provisioned to a test site and verified (see the last section).

## Findings you may want to act on

1. **Event banner URLs were malformed in the export, now fixed in `PnP-Provisioning-Clean.xml` only.** They read like `https:{site}{site}m365x58285237.sharepoint.com{site}SiteAssets…` because the site was exported from the tenant root, where `{site}` is `/`, so every `/` was tokenised. All 18 `BannerUrl`/`BannerImageUrl` values in the 9 Events rows were rewritten to the portable `{site}`-token form: `{site}/SiteAssets/SitePages/Event(11)/…` for both halves of `BannerUrl`, `{site}/_layouts/15/getpreview.ashx?path={site}/SiteAssets/…` for `BannerImageUrl`, and plain `https://cdn.hubblecontent.osi.office.net/…` for the stock images. The source tenant host name was dropped. The `Id=` and `listId=` query parameters were left as exported. **`PnP-Provisioning.xml` still has the malformed values; it is kept as the raw source export and was intentionally not edited.**
2. **A broken thumbnail reference.** The page *That's a great idea…* points to `SitePages/That-s-a-great-idea--How-to-help-introverts-be-heard-in-meetings/dashboard-news.jpg`, which does not exist. The image exists as `SitePages/Dashboard/dashboard-news.jpg`. Pre-existing; left as is by decision (the page is not promoted news, and its header image comes from a CDN URL).
3. **The bloat came from `"includeItems": true` on Site Assets** in [PnPSite.json](_exportConfig/PnPSite.json). Re-exporting with it will bring back every library item.
4. **Contoso.zip** is rebuilt from the current folder (77.0 MiB, including the README and `media`) and is checked against the folder after each change.
5. **Git:** this work did not stage or commit anything.

## Image compression (applied after the cleanup)

To bring the ZIP under GitHub's 100 MiB limit, the 22 images of 250 KiB or more were recompressed **in place** with unchanged file names, extensions and pixel dimensions, so no XML or reference changes were needed.

- **JPEG (15 files):** mozjpeg quality 85, 4:2:0, progressive. EXIF was stripped, and the 3 Adobe RGB images were converted to sRGB. Measured quality against the originals was 33.6–49.0 dB PSNR, with no visible difference at 100% zoom apart from slightly smoothed grain.
- **PNG (6 files):** lossless repack, and the alpha channel was dropped where it was fully opaque. A pixel comparison confirmed every PNG is **pixel-identical** to the original. `Home/3307752173-Rectangle-1.png` was left as is because there was no meaningful gain.
- **Result:** SiteAssets went from 210.3 MiB to 72.8 MiB. The Contoso ZIP built from the compressed folder was 75.8 MiB (77.0 MiB after the README and screenshots were added later).
- **Originals:** backed up outside the repo (local to the machine that ran this work; these files were mostly untracked) at `C:\Users\mdent\.copilot\session-state\06350047-0f99-4053-824b-b6e4f1c7467c\files\imgwork\originals\Contoso`. Per-file sizes and checks are in `imgwork\compress-Contoso.csv` in the same folder.

## Undo

Nothing was deleted; files were moved to
`C:\Users\mdent\.copilot\session-state\06350047-0f99-4053-824b-b6e4f1c7467c\files\contoso-cleanup-quarantine`:

- `SiteAssets\…` holds the 100 removed files in their original relative paths.
- `xml-original\` holds both XML files as they were before the cleanup.
- `plan.csv` lists every file with its action, reason, size, hash and duplicate partner.

To restore, copy `SiteAssets\*` back into `PnPProvisioning\SiteAssets` and the two XMLs back into `PnPProvisioning`. Delete the quarantine folder once you are satisfied. (The backup, quarantine and `imgwork` folders are local to the machine that ran this work, not part of the repo.)

## Later changes and live verification

Changes made after the cleanup. Template fixes are in `PnP-Provisioning-Clean.xml` only.

**Template**
- 13 image URLs got the missing `{site}` prefix: 10 page `ThumbnailUrl` values, the *Contoso Mark 8* banner (`ServerRelativeImageUrl`) and the 2 `getpreview` thumbnails (Arizona, "That's a great idea…").
- Events banner values use the `{site}` token form (see finding 1).
- The second Events web part ("IN OUR FIELD") reads the site's Events list (`dataSource` 7, provider `Event`, `selectedListId` `{listid:Events}`, no hard-coded sites). Both Events web parts use the range 2022-11-01 to 2026-11-10.
- Footer `Logo` is empty (`{site}/` caused `Cannot open "/"`), and the site header layout is Standard to match the script.

**Script and data**
- `ApplyPnPProvisioningTemplate.ps1`: the logo, thumbnail and header-background paths include `.png`, and the ACE path matches the folder case (`ACEs/Contoso.ACEs.csv`). The theme-import block was removed (the theme is a manual README step).
- `ACEs/Contoso.ACEs.csv`: the two third-party ACEs (*My sites*, *Viva Learning*) were replaced with CardDesigner cards.
- `Font Packages/Contoso.Fonts.json`: package title is **Contoso.Fonts**. `utils/exportFontPackages.ps1` also accepts `<site>.Fonts` titles.

**README and media**
- Typos, the colors table, section order and the theme text were fixed. The font package step now names **Contoso.Fonts**.
- `media/` holds 12 lowercase `.jpg` files (10 used by the README). One screenshot (`contoso-review-font-package.jpg`) was retouched to read "Contoso.Fonts" instead of "Contoso".

**Verified on a live test site (MARCTEST11)**
- Site logo returns 200, and the header layout is Standard.
- All 11 promoted pages have thumbnails that load.
- "IN OUR FIELD" resolves to the site's own Events list (9 events), and all 4 local event banners return 200.
- The Dashboard shows 4 cards (*Last incident*, *My sites*, *Assigned Tasks*, *Viva Learning*), and all 9 Resources icons load.

**Accepted as is**
- *That's a great idea…* keeps its missing thumbnail (see finding 2).
- The Events end date stays 2026-11-10.
- `contoso-fonts.jpg`, `Contoso.jpg` and the 13 `Pages Metadata` images are kept.
- The *Viva Learning* card links to a public page, not a Teams deep link.
- Seen but not fixed: the browser requests `Aptos*.ttf` relative to the page and gets 404s (also seen on the source site), and the `News-post.aspx` template page points at a stock tile image that returns 404.

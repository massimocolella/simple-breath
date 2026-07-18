# Store Submission Materials

This directory contains the copy and screenshots prepared for the first Garmin
Connect IQ Store submission.

## Files

- `LISTING.md`: English and Italian descriptions and release notes.
- `assets/cover.png`: required 500×500 Store cover image.
- `assets/hero.png`: optional 1440×720 promotional hero image.
- `assets/*.svg`: editable vector sources for the Store artwork.
- `screenshots/fr265-ready.png`: ready screen on a 416×416 AMOLED target.
- `screenshots/fr265-running.png`: running screen on a 416×416 AMOLED target.
- `screenshots/fr265-save-menu.png`: explicit Save/Discard menu on AMOLED.
- `screenshots/fr55-ready.png`: compact-display QA capture at 208×208.
- `screenshots/fr55-running.png`: compact running-screen QA capture at 208×208.

The `.iq` upload package is generated into `bin/` and intentionally excluded
from version control.

## Submission checklist

- Export a signed `.iq` package with all products from `manifest.xml`.
- Upload the package and wait for Garmin's binary validation.
- Add the English and Italian listing copy from `LISTING.md`.
- Upload the Forerunner 265 screenshots; retain the Forerunner 55 captures as
  evidence that the compact layout was tested.
- Confirm the free price, Health & Fitness category, support contact, source
  URL, and privacy-policy URL.
- Preview the listing and submit it for Garmin review.

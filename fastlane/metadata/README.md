# App Store listing metadata

`fastlane deliver` reads this tree. Push it with the `store` / `metadata`
lanes (see `../../RELEASING.md`). Listing copy is adapted from the Android
app's `fastlane/metadata/android/en-US/` — the original wording was already
platform-neutral, so only the Play-specific phrasing was removed.

## Layout

```
metadata/
  copyright.txt                     App-wide copyright line
  en-US/
    name.txt                        App name        (30 char max)
    subtitle.txt                    Subtitle        (30 char max)
    promotional_text.txt            Promo text      (170 char max, no review needed)
    keywords.txt                    Keywords        (100 char max, comma-separated)
    description.txt                 Description      (4000 char max)
    release_notes.txt               "What's New" for the current version
    support_url.txt                 Support URL
    privacy_url.txt                 Privacy policy URL
    beta_app_description.txt        TestFlight beta description (read by the `beta` lane,
                                    not deliver — shown to external testers)
  review_information/
    notes.txt                       Notes for App Review
```

## Locales

English only. Add a sibling locale directory (same files as `en-US`, minus
the URLs) plus a matching row in `../screenshot_captions.yml` when a
translation exists.

## Category

Not stored here (picked directly in App Store Connect, same as the Android
app's Play category isn't stored in its repo). The live listing is under
**Education**.

## Review contact details

First/last name, email, and phone for App Review are **not** kept in this
repo. Set them once directly in App Store Connect > App Review Information —
`deliver` leaves those fields alone when the matching file is absent from
`review_information/`. The screen-recording script and the full review-notes
draft live in `../recording_script.md` and `../review_notes.md`.

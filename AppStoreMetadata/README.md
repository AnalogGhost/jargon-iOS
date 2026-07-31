# App Store Connect listing metadata

Paste these directly into the matching App Store Connect fields under App Information / Version Information. Adapted from the Android app's `fastlane/metadata/android/en-US/` listing copy (Play Store wording removed; nothing else needed changing, since the original copy was already platform-neutral).

- `name.txt` → App Name (30 char limit)
- `subtitle.txt` → Subtitle (30 char limit)
- `promotional_text.txt` → Promotional Text (170 char limit, editable without a new review)
- `keywords.txt` → Keywords (100 char limit, comma-separated)
- `description.txt` → Description (4000 char limit)

## Category

Not stored in this repo (picked directly in App Store Connect, same as Android's Play category isn't stored here either). Recommended: **Reference** as the primary category.

## Screenshots

Not yet captured. Apple only strictly requires the largest device per family: 6.9" iPhone (1320×2868 px), plus 13" iPad (2064×2752 px) since this app supports iPad. Suggested shot list, mirroring Android's `fastlane/metadata/android/*/images/phoneScreenshots/`:

1. Entry list — browse view with the A-Z scrubber
2. Search — instant search narrowing results
3. Entry detail — definition with tappable cross-references
4. Entry detail — favorites star toggled on
5. Favorites filter — list filtered to favorited entries only
6. About — license and dictionary attribution

Capture on a real device or the largest iPhone/iPad simulator (`xcrun simctl io <device> screenshot`) once you've clicked through the app yourself.

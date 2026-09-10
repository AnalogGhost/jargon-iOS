# Repository guidelines

## Project structure

Jargon for iOS is a SwiftUI offline reader for the Jargon File, targeting
iOS 17 and universal (iPhone + iPad). Source code is under `Sources/`, unit
tests are under `Tests/`, UI tests (including the screenshot walkthrough) are
under `UITests/`, App Store copy and screenshots are under `fastlane/metadata/`
and `fastlane/screenshots/`, and `project.yml` is the canonical XcodeGen
project definition. The bundled dictionary is `Sources/jargon.json`. Generated
`.xcodeproj` files are ignored and must not be committed.

## Development commands

- `xcodegen generate` regenerates `Jargon.xcodeproj` from `project.yml`.
- `xcodebuild -scheme Jargon -destination 'platform=iOS Simulator,name=iPhone 16' test`
  runs the unit + functional UI tests (any installed iPhone simulator works).
- `swift build --package-path Tools/ScreenshotComposer` builds the screenshot
  compositor.

## Coding and testing

- Preserve fully offline operation and the zero-permission, zero-network design.
- Keep dictionary parsing and filtering in `Sources/Data/`, view models in
  `Sources/ViewModels/`, and SwiftUI presentation in `Sources/Views/`.
- Add or update XCTest coverage for changes to parsing, filtering, favorites,
  and cross-reference navigation.
- Regenerate the project after changing `project.yml`, then build and run the
  relevant tests before committing.
- Keep signing credentials, derived data, archives, and generated projects out
  of Git.

## Releases

Release automation is fastlane, run locally. Full procedure in `RELEASING.md`.

- A version bump (`MARKETING_VERSION` in `project.yml`) needs a matching
  `fastlane/metadata/en-US/release_notes.txt`.
- The `store`, `beta`, and `release` lanes upload to App Store Connect and
  create git tags / GitHub releases — run them only on explicit request. Upload
  lanes default to a dry run (`verify_only:true`).
- Never commit `*.p8` App Store Connect keys, `fastlane/.env.default`, or
  `.ipa`/`.xcarchive` build output.
- `bundle exec fastlane screenshots` regenerates App Store screenshots
  (`snapshot` walkthrough + `Tools/ScreenshotComposer`); the resulting PNGs
  under `fastlane/screenshots/` are committed by hand, never by CI.

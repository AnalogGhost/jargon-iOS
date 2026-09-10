# Screen recording script — App Review resubmission

Run through this on a real physical device with the app installed (borrowed
phone + Xcode Run, or TestFlight — see C2K's notes for the mechanics, same
approach applies here). No narration needed — Apple just wants to see the
flow happen. Target ~60–90 seconds; this app is simple, don't pad it out.

Device: newest iPhone available, on the newest non-beta iOS. The app is
universal (iPhone + iPad), so if you also test on an iPad at some point,
note that in item 2 of the review notes — but only one device is needed for
the recording itself.

Before starting: fully close the app if it's already open, so the recording
captures a true cold launch.

| # | Action | What it demonstrates |
|---|--------|----------------------|
| 1 | Tap the app icon to launch from a cold start | Launch |
| 2 | Land directly on the alphabetical entry list — scroll a few screens using the fast-scroll index on the side | Core browsing UI, no login wall |
| 3 | Tap the search field, type a term (e.g. "kluge" or "bogon"), show results filtering live as you type | Search |
| 4 | Tap into a result to open its full definition | Reading an entry |
| 5 | Tap a cross-referenced term inside that definition's text to jump straight to the linked entry | Cross-reference navigation — the app's signature feature |
| 6 | Tap the favorite toggle/star on an entry | Favoriting |
| 7 | Navigate to the Favorites filter/tab — show the just-favorited entry listed there | Favorites view |
| 8 | Tap "Surprise me" — show it landing on a random entry | Random entry feature |

Not needed in the recording (app has none of these): account registration,
login, account deletion, purchases/subscriptions, user-generated content,
content reporting/blocking, ATT prompt, or any permission dialog — this app
requests zero permissions and makes zero network requests, so there's
nothing else to capture.

## After recording

- Trim dead air at the start/end so it opens right at app launch.
- Crop out any device-farm browser chrome if that's how you captured it
  (not mandatory, but cleaner).
- Export as .mp4/.mov and attach it in App Store Connect per their upload
  instructions for the review resolution.

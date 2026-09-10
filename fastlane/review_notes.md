# App Review Notes — response to Guideline 2.1 rejection

Paste into App Store Connect → App Review Information → Notes. Fill in the
`[ ]` placeholders before submitting.

---

**1. Screen recording**

[Attach separately per App Store Connect's instructions — it doesn't go in
the Notes field itself.]

Record on a physical device running the latest iOS/iPadOS. Suggested flow
(~60–90s — this app is simpler than a typical submission, so keep it tight):

1. Launch the app from the home screen (cold launch).
2. Show the alphabetical entry list with the fast-scroll index — scroll
   through it.
3. Use search — type a term, show results filtering live.
4. Open an entry, tap a cross-referenced term inside its definition to jump
   to that entry (this is the app's signature interaction).
5. Favorite an entry (tap the favorite toggle), then switch to the
   Favorites filter to show it listed there.
6. Tap "Surprise me" to jump to a random entry.

No account registration, login, purchases/subscriptions, user-generated
content, or sensitive-data/device-capability prompts exist in this app —
none of those apply, and there's nothing else to demonstrate.

**2. Devices and OS versions tested**

- iPhone 17, iOS 26.6
- iPad mini (6th generation), iPadOS 26.6

**3. App description and target audience**

Jargon is a fully offline reader for the Jargon File — a long-running
hacker-culture dictionary/glossary (compiled by Eric S. Raymond and Guy L.
Steele, continued today as a community project) that documents the
vocabulary, slang, and folklore of software/hacker culture, including the
original meaning of the word "hacker" itself.

Target audience: programmers, computer science students, and anyone
interested in hacker/computing culture and its history and terminology.
The app solves the problem of the Jargon File's canonical text being
scattered across old web mirrors of varying quality — it packages the
full community edition into a fast, searchable, cross-referenced,
offline-first reading experience with no ads or friction.

**4. Setup and access instructions**

No login, account, or sample data is required. The app has no account
system at all. On first launch, the user is shown the full alphabetical
entry list immediately — all 2,300+ entries and all features (search,
cross-reference navigation, favorites, random entry) are available with no
setup step.

**5. External services used**

None. The app makes no network requests whatsoever and integrates no
third-party SDKs, analytics, crash reporting, or ad networks. The entire
dictionary (2,300+ entries) ships bundled inside the app binary as local
data; nothing is fetched remotely, ever. Favorited entries are stored
locally on-device only. This is documented in the app's Privacy Policy and
reflected in its Privacy Manifest (no tracking, no collected data types).

**6. Regional differences**

The app functions identically in every region — there is no server-side
content, no region locking, and no pricing/purchases of any kind.

**7. Regulated industry / protected third-party material**

The app is not in a regulated industry, but it does bundle third-party
content: the dictionary text is the Jargon File community edition, licensed
under CC BY-SA 4.0 (github.com/agiacalone/jargonfile). This is a permissive
license that explicitly allows redistribution and adaptation, including in
apps, with attribution — which is given both in-app and in the App Store
description ("Dictionary content is CC BY-SA 4.0 from the Jargon File
community edition"). [Attach or link the specific CC BY-SA 4.0 license text
/ the jargonfile repo's license file if the reviewer wants to verify terms
directly.]

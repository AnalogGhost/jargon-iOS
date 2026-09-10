# Jargon

A fully offline reader for the Jargon File — the hacker culture dictionary that gave the word "hacker" its original meaning — for iOS 17+.

## Features

- Browse 2,300+ entries alphabetically, with a fast-scroll index
- Instant search across terms and definitions
- Tap any cross-referenced term to jump straight to it
- Favorite entries and filter down to just those
- "Surprise me" with a random entry
- Zero permissions, zero network access — the dictionary ships inside the app; nothing ever leaves the device

## Requirements

- Xcode 16+
- iOS 17+ device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project

## Building

```sh
brew install xcodegen
xcodegen generate
open Jargon.xcodeproj
```

Set your development team in Xcode under Signing & Capabilities, then build and run.

## Releasing

App Store releases are cut locally with fastlane. See [RELEASING.md](RELEASING.md).

## License

Copyright (C) 2026 Mathew Brown

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

See [LICENSE](LICENSE) for the full text.

Dictionary content is CC BY-SA 4.0 from the [Jargon File community edition](https://github.com/agiacalone/jargonfile).

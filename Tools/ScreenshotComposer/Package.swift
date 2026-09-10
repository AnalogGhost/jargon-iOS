// swift-tools-version:5.9
import PackageDescription

// Composites the raw App Store screenshots (fastlane/screenshots/raw) into the
// framed + captioned marketing set (fastlane/screenshots/framed) that deliver
// uploads. Green-phosphor CRT-terminal look, ported from the Android app's
// tools/screenshot-composer; geometry is per-device because Apple requires
// exact screenshot sizes.
let package = Package(
    name: "ScreenshotComposer",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "screenshot-composer", targets: ["ScreenshotComposer"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotComposer",
            path: "Sources/ScreenshotComposer",
            resources: [.process("Resources")]
        )
    ]
)

import AppKit
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Framed + captioned App Store screenshot compositor. Reads the raw per-locale
// screenshots under fastlane/screenshots/raw, draws each onto a fixed-size
// canvas — near-black green-cast background, phosphor radial glow, a shell-prompt
// caption in the bundled VT323 terminal face, a sharp-cornered phosphor box
// frame, a faint ">" prompt-glyph watermark, and CRT scanlines — and writes the
// result to fastlane/screenshots/framed. Visual language is ported from the
// Android app's tools/screenshot-composer; the geometry is per-device because
// Apple requires an exact screenshot size (unlike Play).

// MARK: - Palette

func rgb(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
    CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}
let BACKGROUND = rgb(0x06, 0x0A, 0x06)   // near-black with a faint green cast
let PHOSPHOR   = rgb(0x4A, 0xE2, 0x4A)   // bright scan-line green (caption, cursor, frame)
let DIM_GREEN  = rgb(0x1B, 0x5E, 0x20)   // brand TerminalGreen (glow, shell prompt)

let WATERMARK_ALPHA: CGFloat = 0.06
let BLOOM_ALPHA: CGFloat = 0.30
let SCANLINE_ALPHA: CGFloat = 0.10
let SCANLINE_PITCH: CGFloat = 3

let PROMPT = "> "
let CURSOR = "\u{2588}"                    // full block
let CAPTION_LINE_SPACING: CGFloat = 1.10

// MARK: - Per-device geometry

// Apple accepts exactly one size per required display: 6.9" iPhone is 1320x2868,
// 13" iPad is 2064x2752. The raw capture already comes in at that size; the
// canvas matches it and the screenshot is scaled down to sit inside the frame
// below the caption band.
struct Profile {
    let canvasW: CGFloat
    let canvasH: CGFloat
    let sideMargin: CGFloat
    let captionBand: CGFloat   // reserved height at the top for the caption
    let captionGap: CGFloat    // gap between the caption band and the frame
    let bottomMargin: CGFloat
    let frameBorder: CGFloat
    let captionFontSize: CGFloat
}

let PROFILES: [Profile] = [
    // 6.9" iPhone
    Profile(canvasW: 1320, canvasH: 2868, sideMargin: 96, captionBand: 360,
            captionGap: 40, bottomMargin: 104, frameBorder: 8, captionFontSize: 108),
    // 13" iPad
    Profile(canvasW: 2064, canvasH: 2752, sideMargin: 150, captionBand: 340,
            captionGap: 44, bottomMargin: 130, frameBorder: 10, captionFontSize: 120)
]

func profile(forWidth w: Int, height h: Int) -> Profile {
    if let exact = PROFILES.first(where: { Int($0.canvasW) == w && Int($0.canvasH) == h }) {
        return exact
    }
    // Unknown size (a simulator that renders slightly off, say): fall back to the
    // profile with the nearest aspect ratio and stretch its canvas to the raw.
    let ar = CGFloat(w) / CGFloat(h)
    let base = PROFILES.min { abs($0.canvasW / $0.canvasH - ar) < abs($1.canvasW / $1.canvasH - ar) }!
    return Profile(canvasW: CGFloat(w), canvasH: CGFloat(h), sideMargin: base.sideMargin,
                   captionBand: base.captionBand, captionGap: base.captionGap,
                   bottomMargin: base.bottomMargin, frameBorder: base.frameBorder,
                   captionFontSize: base.captionFontSize)
}

// MARK: - Bundled font

let CAPTION_FONT_NAME: String = {
    guard let url = Bundle.module.url(forResource: "VT323-Regular", withExtension: "ttf") else {
        FileHandle.standardError.write(Data("screenshot-composer: VT323-Regular.ttf missing from bundle, using a system mono\n".utf8))
        return NSFont.monospacedSystemFont(ofSize: 12, weight: .bold).fontName
    }
    var err: Unmanaged<CFError>?
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
    // "VT323" is the family name; registration is idempotent enough for a one-shot tool.
    return "VT323"
}()

func captionFont(_ size: CGFloat) -> CTFont {
    let f = CTFontCreateWithName(CAPTION_FONT_NAME as CFString, size, nil)
    return f
}

// MARK: - Entry point

let root = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath
let fm = FileManager.default

let fastlaneDir = (root as NSString).appendingPathComponent("fastlane")
let rawRoot = (fastlaneDir as NSString).appendingPathComponent("screenshots/raw")
let outRoot = (fastlaneDir as NSString).appendingPathComponent("screenshots/framed")
let captionsFile = (fastlaneDir as NSString).appendingPathComponent("screenshot_captions.yml")

let captions = parseCaptions(captionsFile)

guard let localeDirs = try? fm.contentsOfDirectory(atPath: rawRoot).sorted() else {
    fail("No raw screenshots found under \(rawRoot) — run `fastlane snapshot` first.")
}

var composed = 0
for locale in localeDirs {
    let inDir = (rawRoot as NSString).appendingPathComponent(locale)
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: inDir, isDirectory: &isDir), isDir.boolValue else { continue }

    let outDir = (outRoot as NSString).appendingPathComponent(locale)
    try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

    let pngs = ((try? fm.contentsOfDirectory(atPath: inDir)) ?? [])
        .filter { $0.lowercased().hasSuffix(".png") }
        .sorted()

    for png in pngs {
        // snapshot names files "<device>-<screen>.png". Device names can contain
        // dashes ("iPad Pro 13-inch (M5)"), so match by the caption key as a
        // suffix rather than splitting on a separator.
        let stem = (png as NSString).deletingPathExtension
        guard let screen = (captions.keys.first { stem == $0 || stem.hasSuffix("-" + $0) }) else {
            fail("No caption key matches '\(stem)' (fastlane/screenshot_captions.yml)")
        }
        guard let caption = captions[screen]?[locale] else {
            fail("No caption for '\(screen)' in locale '\(locale)' (fastlane/screenshot_captions.yml)")
        }
        let rawPath = (inDir as NSString).appendingPathComponent(png)
        guard let raw = loadCGImage(rawPath) else { fail("Could not read \(rawPath)") }

        let framed = composite(raw: raw, caption: caption)
        let outPath = (outDir as NSString).appendingPathComponent(png)
        writePNG(framed, to: outPath)
        composed += 1
    }
}

print("Composed \(composed) screenshot(s) into \(outRoot)")

// MARK: - Compositing

func composite(raw: CGImage, caption: String) -> CGImage {
    let p = profile(forWidth: raw.width, height: raw.height)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil,
        width: Int(p.canvasW), height: Int(p.canvasH),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fail("Could not create bitmap context") }

    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // Everything below is in CoreGraphics' native y-up space. `fromTop` converts a
    // distance measured from the top of the canvas into a y-up origin.
    func fromTop(_ topY: CGFloat, height h: CGFloat) -> CGFloat { p.canvasH - topY - h }

    // Fit the raw screenshot into the area below the caption band.
    let availW = p.canvasW - 2 * p.sideMargin
    let availTop = p.captionBand + p.captionGap
    let availH = p.canvasH - availTop - p.bottomMargin
    let rawW = CGFloat(raw.width), rawH = CGFloat(raw.height)
    let scale = min(availW / rawW, availH / rawH)
    let shotW = (rawW * scale).rounded()
    let shotH = (rawH * scale).rounded()
    let shotX = ((p.canvasW - shotW) / 2).rounded()
    let shotTopY = availTop + ((availH - shotH) / 2).rounded()
    let shotY = fromTop(shotTopY, height: shotH)
    let frameTopYUp = shotY + shotH + p.frameBorder

    // Background
    ctx.setFillColor(BACKGROUND)
    ctx.fill(CGRect(x: 0, y: 0, width: p.canvasW, height: p.canvasH))

    // Phosphor radial glow, brightest near the frame's top edge so it lands in
    // the visible caption band / side margins rather than under the screenshot.
    let glow = CGGradient(colorsSpace: cs, colors: [DIM_GREEN, BACKGROUND] as CFArray, locations: [0, 1])!
    let glowCenter = CGPoint(x: p.canvasW / 2, y: frameTopYUp)
    ctx.saveGState()
    ctx.drawRadialGradient(glow, startCenter: glowCenter, startRadius: 0,
                           endCenter: glowCenter, endRadius: p.canvasW * 0.9,
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    drawWatermarkPrompt(ctx, p)
    drawCaption(ctx, caption, p)

    // Sharp-cornered phosphor box — a CRT/DOS frame, not a rounded card. Soft
    // outer glow stroke, then a crisp inner one.
    let frameRect = CGRect(x: shotX - p.frameBorder, y: shotY - p.frameBorder,
                           width: shotW + 2 * p.frameBorder, height: shotH + 2 * p.frameBorder)
    ctx.saveGState()
    ctx.setStrokeColor(PHOSPHOR.copy(alpha: 0.24)!)
    ctx.setLineWidth(p.frameBorder * 3)
    ctx.stroke(frameRect)
    ctx.setStrokeColor(PHOSPHOR)
    ctx.setLineWidth(p.frameBorder)
    ctx.stroke(frameRect)
    ctx.restoreGState()

    // Screenshot, square corners to match the frame.
    ctx.draw(raw, in: CGRect(x: shotX, y: shotY, width: shotW, height: shotH))

    drawScanlines(ctx, p)

    guard let image = ctx.makeImage() else { fail("Could not render image") }
    return image
}

// MARK: - Caption

/// The caption rendered as a shell line: a dim-green "> " prompt, the phosphor
/// caption text, and a trailing block cursor — left-aligned in the caption band,
/// with an offset low-alpha bloom pass behind the crisp glyphs to fake CRT
/// phosphor spread. Wrapped lines are indented two spaces under the prompt.
func drawCaption(_ ctx: CGContext, _ caption: String, _ p: Profile) {
    let font = captionFont(p.captionFontSize)
    let maxWidth = p.canvasW - 2 * p.sideMargin

    func width(_ s: String) -> CGFloat {
        let attr = NSAttributedString(string: s, attributes: [.font: font])
        return CTLineGetTypographicBounds(CTLineCreateWithAttributedString(attr), nil, nil, nil)
    }

    let body = wrap(caption, maxWidth: maxWidth) { width(PROMPT + $0) }

    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    _ = CTLineGetTypographicBounds(
        CTLineCreateWithAttributedString(NSAttributedString(string: "Ag", attributes: [.font: font])),
        &ascent, &descent, &leading)
    let lineHeight = (ascent + descent + leading) * CAPTION_LINE_SPACING
    let blockHeight = lineHeight * CGFloat(body.count)
    var baselineFromTop = (p.captionBand - blockHeight) / 2 + ascent

    for (i, line) in body.enumerated() {
        let prefix = i == 0 ? PROMPT : "  "
        let text = i == body.count - 1 ? prefix + line + CURSOR : prefix + line
        drawGlowLine(ctx, text, prefixLen: prefix.count, x: p.sideMargin,
                     baselineY: p.canvasH - baselineFromTop, font: font)
        baselineFromTop += lineHeight
    }
}

func drawGlowLine(_ ctx: CGContext, _ text: String, prefixLen: Int, x: CGFloat, baselineY: CGFloat, font: CTFont) {
    func line(_ s: String, _ color: CGColor) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(
            string: s, attributes: [.font: font, .foregroundColor: NSColor(cgColor: color) ?? .green]))
    }

    // Bloom: the whole string in phosphor, low alpha, nudged around the crisp position.
    ctx.saveGState()
    ctx.setAlpha(BLOOM_ALPHA)
    for dx in stride(from: CGFloat(-2), through: 2, by: 2) {
        for dy in stride(from: CGFloat(-2), through: 2, by: 2) where !(dx == 0 && dy == 0) {
            ctx.textPosition = CGPoint(x: x + dx, y: baselineY + dy)
            CTLineDraw(line(text, PHOSPHOR), ctx)
        }
    }
    ctx.restoreGState()

    // Crisp: dim-green prompt/indent, phosphor for the caption text.
    let chars = Array(text)
    let prefix = String(chars.prefix(prefixLen))
    let rest = String(chars.dropFirst(prefixLen))
    ctx.textPosition = CGPoint(x: x, y: baselineY)
    CTLineDraw(line(prefix, brighten(DIM_GREEN)), ctx)
    let prefixWidth = CTLineGetTypographicBounds(line(prefix, DIM_GREEN), nil, nil, nil)
    ctx.textPosition = CGPoint(x: x + CGFloat(prefixWidth), y: baselineY)
    CTLineDraw(line(rest, PHOSPHOR), ctx)
}

func wrap(_ text: String, maxWidth: CGFloat, width: (String) -> CGFloat) -> [String] {
    var lines: [String] = []
    var current = ""
    for word in text.split(separator: " ").map(String.init) {
        let candidate = current.isEmpty ? word : current + " " + word
        if current.isEmpty || width(candidate) <= maxWidth {
            current = candidate
        } else {
            lines.append(current)
            current = word
        }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
}

func brighten(_ c: CGColor) -> CGColor {
    let comps = c.components ?? [0, 1, 0, 1]
    func up(_ v: CGFloat) -> CGFloat { min(1, v * 1.4 + 0.15) }
    return CGColor(srgbRed: up(comps[0]), green: up(comps[1]), blue: up(comps[2]), alpha: 1)
}

// MARK: - Watermark

/// The terminal-prompt glyph from the app icon (a ">" chevron plus a "_" cursor
/// underscore, in the icon's 0-108 coordinate space) drawn large and faint in
/// the bottom-right corner so the screenshots carry the app's motif.
func drawWatermarkPrompt(_ ctx: CGContext, _ p: Profile) {
    ctx.saveGState()
    defer { ctx.restoreGState() }

    // Flip into a y-down space so the glyph coordinates map straight across.
    ctx.translateBy(x: 0, y: p.canvasH)
    ctx.scaleBy(x: 1, y: -1)

    let glyphScale = p.sideMargin * 3.4 / 54
    let targetX = p.canvasW - 140
    let targetY = p.canvasH - 140
    ctx.translateBy(x: targetX - 62 * glyphScale, y: targetY - 54 * glyphScale)
    ctx.scaleBy(x: glyphScale, y: glyphScale)

    ctx.setAlpha(WATERMARK_ALPHA)
    ctx.setStrokeColor(PHOSPHOR)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(8)

    ctx.beginPath()
    ctx.move(to: CGPoint(x: 38, y: 32))
    ctx.addLine(to: CGPoint(x: 60, y: 54))
    ctx.addLine(to: CGPoint(x: 38, y: 76))
    ctx.strokePath()

    ctx.beginPath()
    ctx.move(to: CGPoint(x: 68, y: 76))
    ctx.addLine(to: CGPoint(x: 86, y: 76))
    ctx.strokePath()
}

// MARK: - Scanlines

func drawScanlines(_ ctx: CGContext, _ p: Profile) {
    ctx.saveGState()
    defer { ctx.restoreGState() }
    ctx.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: SCANLINE_ALPHA))
    ctx.setLineWidth(1)
    var y: CGFloat = 0
    while y < p.canvasH {
        ctx.move(to: CGPoint(x: 0, y: y))
        ctx.addLine(to: CGPoint(x: p.canvasW, y: y))
        y += SCANLINE_PITCH
    }
    ctx.strokePath()
}

// MARK: - Captions file

/// Parses the narrow two-level shape used by fastlane/screenshot_captions.yml:
///   <screen>:
///     <locale>: "<caption>"
func parseCaptions(_ path: String) -> [String: [String: String]] {
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("Missing caption file: \(path)")
    }
    let screenKey = try! NSRegularExpression(pattern: #"^(\S+):\s*$"#)
    let localeLine = try! NSRegularExpression(pattern: #"^\s{2}([\w-]+):\s*"(.*)"\s*$"#)

    var result: [String: [String: String]] = [:]
    var current: String?

    for rawLine in text.components(separatedBy: .newlines) {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

        let range = NSRange(rawLine.startIndex..., in: rawLine)
        if let m = screenKey.firstMatch(in: rawLine, range: range) {
            current = substr(rawLine, m.range(at: 1))
            result[current!] = result[current!] ?? [:]
            continue
        }
        if let m = localeLine.firstMatch(in: rawLine, range: range), let screen = current {
            result[screen, default: [:]][substr(rawLine, m.range(at: 1))] = substr(rawLine, m.range(at: 2))
        }
    }
    return result
}

func substr(_ s: String, _ r: NSRange) -> String {
    Range(r, in: s).map { String(s[$0]) } ?? ""
}

// MARK: - Image IO

func loadCGImage(_ path: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
        fail("Could not create PNG destination at \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { fail("Could not write \(path)") }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("screenshot-composer: " + message + "\n").utf8))
    exit(1)
}

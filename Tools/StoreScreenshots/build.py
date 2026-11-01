#!/usr/bin/env python3
"""Composes the App Store screenshot sets from the raw captures.

Reads the raw screenshots that `fastlane snapshot` writes to fastlane/screenshots/raw/<locale>
(one set per device in the Snapfile), lays each slide out as HTML with the copy from captions.json,
and renders it with headless Chrome into fastlane/screenshots/framed/<locale>, which deliver uploads:
1320x2868 for the 6.9" iPhone and 2064x2752 for the 13" iPad. Ported from the Android app's
tools/store-screenshots/build.py so both stores share one design.

Usage: python3 Tools/StoreScreenshots/build.py [locale ...]
Set CHROME to the Chrome binary if it isn't in the default macOS location.
"""
import html
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
RAW = ROOT / "fastlane/screenshots/raw"
OUT = ROOT / "fastlane/screenshots/framed"
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

BACKGROUND = "#0D1A10"
INK = "#FFFFFF"
ACCENT = "#81C784"
SUBLINE = "#BFD3C2"

# Canvas, type and device placement per Snapfile device. The raw captures are the same size as
# the canvas. device_top is where the devices start on every slide, below the tallest text block,
# so they line up across the set however many lines a headline takes.
LAYOUTS = {
    "iPhone 16 Pro Max": {
        "width": 1320, "height": 2868, "kind": "phone",
        "text_left": 118, "text_top": 150, "text_width": 1084, "gap": 42,
        "h1": 184, "h1_min": 86, "tracking": -5, "sub": 56, "sub_min": 36, "sub_width": 1000,
        "device_top": 1080,
        "back": (740, 10, 90, -11), "main": (830, 500, 0, 7),
    },
    "iPad Pro 13-inch (M5)": {
        "width": 2064, "height": 2752, "kind": "tablet",
        "text_left": 160, "text_top": 150, "text_width": 1744, "gap": 44,
        "h1": 210, "h1_min": 100, "tracking": -6, "sub": 66, "sub_min": 44, "sub_width": 1500,
        "device_top": 1000,
        "back": (1150, 30, 90, -8), "main": (1250, 760, 0, 6),
    },
}

PAGE = """<!doctype html>
<html lang="{lang}"><head><meta charset="utf-8">
<style>
@font-face {{ font-family: "Jakarta"; src: url("{fonts}/PlusJakartaSans.ttf"); font-weight: 200 800; }}
@font-face {{ font-family: "Manrope"; src: url("{fonts}/Manrope.ttf"); font-weight: 200 800; }}
body {{ margin: 0; }}
.shot {{ position: relative; width: {width}px; height: {height}px; overflow: hidden; background: {bg};
  font-family: "Jakarta", "Manrope", sans-serif; }}
.text {{ position: absolute; left: {text_left}px; top: {text_top}px; width: {text_width}px; display: flex; flex-direction: column; gap: {gap}px; }}
h1 {{ margin: 0; font-size: {h1}px; font-weight: 800; line-height: 1.02; letter-spacing: {tracking}px; color: {ink}; }}
h1 span.line {{ display: block; white-space: nowrap; width: max-content; }}
h1 em {{ font-style: normal; color: {accent}; }}
p {{ margin: 0; max-width: {sub_width}px; font-size: {sub}px; font-weight: 500; line-height: 1.3; color: {subline}; }}
.device {{ position: absolute; }}
.frame {{ position: relative; background: #0E1013; box-shadow: 0 0 0 4px #3A3E46, 0 100px 200px rgba(0,0,0,.55); }}
.frame img {{ display: block; }}
.island {{ position: absolute; left: 50%; border-radius: 999px; background: #050607; }}
.button {{ position: absolute; width: 8px; border-radius: 4px; background: #3A3E46; }}
</style></head>
<body><div class="shot">{body}</div>
<script>
// Shrink the headline until its widest line fits, and the subline until it fits three lines,
// so long translations keep the same layout as English.
document.fonts.ready.then(() => {{
  const h1 = document.querySelector("h1"), p = document.querySelector("p");
  let size = {h1};
  while (size > {h1_min} && Math.max(...[...h1.querySelectorAll(".line")].map(l => l.offsetWidth)) > {text_width}) {{
    size -= 4; h1.style.fontSize = size + "px"; h1.style.letterSpacing = ({tracking} * size / {h1}) + "px";
  }}
  let sub = {sub};
  while (sub > {sub_min} && p.offsetHeight > sub * 1.3 * 3 + 2) {{ sub -= 2; p.style.fontSize = sub + "px"; }}
  document.body.dataset.ready = "1";
}});
</script></body></html>"""


def headline(text):
    lines = []
    for line in text.split("|"):
        escaped = html.escape(line)
        escaped = re.sub(r"\{(.*?)\}", r"<em>\1</em>", escaped)
        lines.append(f'<span class="line">{escaped}</span>')
    return "".join(lines)


def phone(src, width, layout, alt):
    pad = round(width * 0.03)
    screen_w = width - 2 * pad
    screen_h = round(screen_w * layout["height"] / layout["width"])
    radius = round(width * 0.15)
    island_w, island_h = round(screen_w * 0.286), round(screen_w * 0.084)
    return (f'<div class="frame" style="padding:{pad}px;border-radius:{radius}px">'
            f'<div class="button" style="right:-10px;top:{round(width * .62)}px;height:{round(width * .24)}px"></div>'
            f'<div class="button" style="left:-10px;top:{round(width * .5)}px;height:{round(width * .16)}px"></div>'
            f'<div class="button" style="left:-10px;top:{round(width * .72)}px;height:{round(width * .16)}px"></div>'
            f'<img src="{src}" alt="{html.escape(alt)}" style="width:{screen_w}px;height:{screen_h}px;border-radius:{radius - pad}px">'
            f'<div class="island" style="top:{pad + round(screen_w * 0.025)}px;width:{island_w}px;height:{island_h}px;margin-left:-{island_w // 2}px"></div>'
            f'</div>')


def tablet(src, width, layout, alt):
    pad = round(width * 0.035)
    screen_w = width - 2 * pad
    screen_h = round(screen_w * layout["height"] / layout["width"])
    radius = round(width * 0.07)
    return (f'<div class="frame" style="padding:{pad}px;border-radius:{radius}px">'
            f'<div class="button" style="right:{round(width * .1)}px;top:-10px;width:{round(width * .1)}px;height:8px"></div>'
            f'<img src="{src}" alt="{html.escape(alt)}" style="width:{screen_w}px;height:{screen_h}px;border-radius:{radius - pad}px">'
            f'</div>')


def placed(content, left, top, rotate):
    return (f'<div class="device" style="left:{left}px;top:{top}px;transform:rotate({rotate}deg)">'
            f'{content}</div>')


def source(locale, device, screen):
    path = RAW / locale / f"{device}-{screen}.png"
    if not path.exists():
        sys.exit(f"Missing capture: {path}")
    return path.as_uri()


def slide_body(locale, device, layout, slide, head, sub):
    text = f'<div class="text"><h1>{headline(head)}</h1><p>{html.escape(sub)}</p></div>'
    frame = phone if layout["kind"] == "phone" else tablet
    devices = ""
    for role in ("back", "main"):
        width, left, top, rotate = layout[role]
        devices += placed(frame(source(locale, device, slide[role]), width, layout, "Jargon screen"),
                          left, layout["device_top"] + top, rotate)
    return text + devices


def render(html_path, png_path, layout):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--allow-file-access-from-files", f"--window-size={layout['width']},{layout['height']}",
                    "--virtual-time-budget=8000", f"--screenshot={png_path}", html_path.as_uri()],
                   check=True, capture_output=True)


def main():
    captions = json.loads((HERE / "captions.json").read_text(encoding="utf-8"))
    locales = sys.argv[1:] or list(captions["copy"])
    with tempfile.TemporaryDirectory() as tmp:
        for locale in locales:
            copy = captions["copy"][locale]
            out_dir = OUT / locale
            out_dir.mkdir(parents=True, exist_ok=True)
            # deliver uploads every PNG in the folder, so clear the previous set first.
            for old in out_dir.glob("*.png"):
                old.unlink()
            built = 0
            for device, layout in LAYOUTS.items():
                for slide, (head, sub) in zip(captions["slides"], copy):
                    if device not in slide.get("devices", [device]):
                        continue
                    page = PAGE.format(lang=locale.split("-")[0], fonts=(HERE / "fonts").as_uri(),
                                       bg=BACKGROUND, ink=INK, accent=ACCENT, subline=SUBLINE,
                                       body=slide_body(locale, device, layout, slide, head, sub),
                                       **{k: v for k, v in layout.items() if not isinstance(v, tuple)})
                    html_path = Path(tmp) / f"{locale}_{device}_{slide['name']}.html"
                    html_path.write_text(page, encoding="utf-8")
                    render(html_path, out_dir / f"{device}-{slide['name']}.png", layout)
                    built += 1
            print(f"{locale}: {built} slides across {len(LAYOUTS)} devices")


if __name__ == "__main__":
    main()

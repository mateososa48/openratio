"""Draw the disk image background at 1x and 2x and combine them into a HiDPI TIFF.

Run: python3 scripts/make_dmg_background.py
The window is 660x420; the app icon sits at (170,190) and the Applications alias
at (490,190), so everything drawn here keeps clear of those two circles.
"""
import os
import subprocess
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "Resources", "dmg")

# Light ground on purpose. Finder paints the icon labels in the system label
# colour, which a background image cannot override, so on a dark ground the
# "OpenRatio" and "Applications" labels come out near-black on near-black. Light
# Mode is the macOS default, so the background matches the app's light panel
# theme instead. (Known trade-off: in Dark Mode those labels go light-on-light.)
W, H = 660, 420
GROUND = (242, 242, 242)
INK = (17, 17, 17)
FAINT = (107, 107, 107)
RULE = (154, 154, 154)
GREEN = (40, 205, 65)
RED = (255, 59, 48)


def font(size: int):
    for path in ("/System/Library/Fonts/SFNSMono.ttf", "/System/Library/Fonts/Menlo.ttc"):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default(size)


def centered(d: ImageDraw.ImageDraw, y: int, text: str, f, fill, scale: int):
    w = d.textlength(text, font=f)
    d.text(((W * scale - w) / 2, y * scale), text, font=f, fill=fill)


def render(scale: int) -> Image.Image:
    img = Image.new("RGB", (W * scale, H * scale), GROUND)
    d = ImageDraw.Draw(img)

    # Wordmark: the 67/33 split bar, then the name.
    bar_w, bar_h, bar_x, bar_y = 44, 7, 246, 56
    split = bar_x + round(bar_w * 0.67)
    d.rectangle([bar_x * scale, bar_y * scale, split * scale, (bar_y + bar_h) * scale], fill=GREEN)
    d.rectangle([split * scale, bar_y * scale, (bar_x + bar_w) * scale, (bar_y + bar_h) * scale], fill=RED)
    d.text(((bar_x + bar_w + 14) * scale, (bar_y - 6) * scale), "OPENRATIO", font=font(17 * scale), fill=INK)

    # Arrow from the app to the Applications alias, clear of both icon circles.
    # Icons sit at x=170 and x=490, so the arrow is centred on x=330.
    y = 190 * scale
    x0, x1 = 258 * scale, 393 * scale
    d.line([x0, y, x1, y], fill=RULE, width=2 * scale)
    head = 9 * scale
    d.polygon([(x1 + head, y), (x1, y - head * 0.55), (x1, y + head * 0.55)], fill=RULE)

    # The one thing every first-time opener needs to know.
    centered(d, 338, "FIRST LAUNCH IS BLOCKED BY MACOS.", font(11 * scale), FAINT, scale)
    centered(d, 358, "SYSTEM SETTINGS  ›  PRIVACY & SECURITY  ›  OPEN ANYWAY", font(11 * scale), FAINT, scale)
    return img


os.makedirs(OUT, exist_ok=True)
one = os.path.join(OUT, "background.png")
two = os.path.join(OUT, "background@2x.png")
tiff = os.path.join(OUT, "background.tiff")
render(1).save(one)
render(2).save(two)
subprocess.run(["tiffutil", "-cathidpicheck", one, two, "-out", tiff], check=True,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("wrote", os.path.relpath(tiff))

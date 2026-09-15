"""Generate the AppIcon set (PNG at every macOS size) from vector-ish drawing code.
Run: python3 scripts/make_icon.py   (needs Pillow)"""
import json, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "Resources", "Assets.xcassets", "AppIcon.appiconset")
SIZES = [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]
BG, GREEN, RED = (15,15,15,255), (40,205,65,255), (255,59,48,255)

def render(px: int) -> Image.Image:
    S = 1024
    img = Image.new("RGBA", (S, S), (0,0,0,0))
    d = ImageDraw.Draw(img)
    # macOS-style rounded square (the system adds the glass frame on macOS 26)
    inset = 100
    d.rounded_rectangle([inset, inset, S-inset, S-inset], radius=190, fill=BG)
    # the ratio bar: 67 / 33
    w, h = 520, 52
    x0, y0 = (S-w)//2, (S-h)//2
    split = x0 + round(w*0.67)
    d.rectangle([x0, y0, split, y0+h], fill=GREEN)
    d.rectangle([split, y0, x0+w, y0+h], fill=RED)
    return img.resize((px, px), Image.LANCZOS)

os.makedirs(OUT, exist_ok=True)
images = []
for pt, scale in SIZES:
    px = pt*scale
    name = f"icon_{pt}x{pt}@{scale}x.png" if scale > 1 else f"icon_{pt}x{pt}.png"
    render(px).save(os.path.join(OUT, name))
    images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
with open(os.path.join(OUT, "Contents.json"), "w") as f:
    json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
print("wrote", len(images), "icons to", os.path.relpath(OUT))

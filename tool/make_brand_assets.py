"""Draws the DailyAds.pk app icon and Play Store feature graphic.

Run from mobile-app/:  python tool/make_brand_assets.py
Outputs to assets/brand/ and the store listing images in fastlane/.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
STORE = ROOT / "fastlane" / "metadata" / "android" / "en-US" / "images"
SERIF = str(ROOT / "assets" / "fonts" / "SourceSerif4-700.ttf")
SERIF_SEMI = str(ROOT / "assets" / "fonts" / "SourceSerif4-600.ttf")

NAVY = (22, 58, 99)
NAVY_DARK = (15, 43, 75)
PAPER = (246, 244, 239)
PAPER_SHADE = (226, 222, 213)
INK = (20, 28, 40)
AMBER = (168, 97, 26)
LINE = (200, 194, 182)


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    px = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        px.line([(0, y), (w, y)], fill=c)
    return img


def sheet(size):
    """The paper sheet glyph on a transparent canvas of `size` x `size`."""
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    # Shadow
    shadow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    x0, y0, x1, y1 = s * 0.20, s * 0.14, s * 0.80, s * 0.86
    sd.rounded_rectangle([x0 + s * 0.012, y0 + s * 0.022, x1 + s * 0.012, y1 + s * 0.022], radius=s * 0.045, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(s * 0.02))
    img.alpha_composite(shadow)

    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x0, y0, x1, y1], radius=s * 0.045, fill=PAPER)

    # Masthead rule (amber) and thin double rule like a newspaper header.
    pad = s * 0.075
    d.rectangle([x0 + pad, y0 + s * 0.085, x1 - pad, y0 + s * 0.085 + s * 0.022], fill=AMBER)

    # Serif "D"
    font = ImageFont.truetype(SERIF, int(s * 0.40))
    bbox = d.textbbox((0, 0), "D", font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (x0 + x1) / 2 - tw / 2 - bbox[0]
    ty = y0 + s * 0.15 - bbox[1]
    d.text((tx, ty), "D", font=font, fill=NAVY)

    # Column text lines
    ly = y0 + s * 0.15 + th + s * 0.055
    lw = s * 0.018
    for i, frac in enumerate([1.0, 0.82, 1.0]):
        yy = ly + i * s * 0.05
        if yy + lw > y1 - s * 0.04:
            break
        d.rounded_rectangle([x0 + pad, yy, x0 + pad + (x1 - x0 - 2 * pad) * frac, yy + lw], radius=lw / 2, fill=LINE)
    return img


def icon_full(size=1024):
    bg = gradient((size, size), NAVY, NAVY_DARK).convert("RGBA")
    bg.alpha_composite(sheet(size))
    return bg


def adaptive_foreground(size=1024):
    # Adaptive icons show the centre 66%; scale the sheet into that zone.
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner = int(size * 0.74)
    glyph = sheet(inner)
    canvas.alpha_composite(glyph, ((size - inner) // 2, (size - inner) // 2))
    return canvas


def feature_graphic():
    w, h = 1024, 500
    img = gradient((w, h), NAVY, NAVY_DARK).convert("RGBA")
    d = ImageDraw.Draw(img)

    # Fanned newspaper sheets on the right.
    for i, (dx, dy, rot) in enumerate([(700, 70, -8), (760, 40, 4), (650, 110, 12)]):
        g = sheet(360).rotate(rot, resample=Image.BICUBIC, expand=True)
        img.alpha_composite(g, (dx - 40, dy - 30))

    title = ImageFont.truetype(SERIF, 86)
    sub = ImageFont.truetype(SERIF_SEMI, 34)
    small = ImageFont.truetype(SERIF_SEMI, 26)
    d.text((64, 120), "DailyAds", font=title, fill=PAPER)
    tw = d.textlength("DailyAds", font=title)
    d.text((64 + tw, 120), ".pk", font=title, fill=(232, 162, 84))
    d.rectangle([66, 232, 186, 238], fill=(232, 162, 84))
    d.text((64, 262), "Pakistan’s newspaper ads,", font=sub, fill=PAPER)
    d.text((64, 306), "every day, on your phone", font=sub, fill=PAPER)
    d.text((64, 378), "Jobs · Tenders · Admissions · Notices", font=small, fill=(182, 191, 203))
    return img.convert("RGB")


def main():
    BRAND.mkdir(parents=True, exist_ok=True)
    STORE.mkdir(parents=True, exist_ok=True)
    full = icon_full()
    full.convert("RGB").save(BRAND / "icon.png")
    adaptive_foreground().save(BRAND / "icon_foreground.png")
    full.convert("RGB").resize((512, 512), Image.LANCZOS).save(STORE / "icon.png")
    feature_graphic().save(STORE / "featureGraphic.png")
    print("wrote", BRAND / "icon.png", STORE / "icon.png", STORE / "featureGraphic.png")


if __name__ == "__main__":
    main()

"""Frames raw emulator screenshots as 1080x1920 (9:16) Play Store images.

Run from mobile-app/:  python tool/make_store_screenshots.py
Reads raw captures from store/screenshots/, writes fastlane phoneScreenshots/.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "store" / "screenshots"
OUT = ROOT / "fastlane" / "metadata" / "android" / "en-US" / "images" / "phoneScreenshots"
SERIF = str(ROOT / "assets" / "fonts" / "SourceSerif4-700.ttf")

NAVY = (22, 58, 99)
NAVY_DARK = (15, 43, 75)
PAPER = (246, 244, 239)
AMBER = (232, 162, 84)

CAPTIONS = {
    "01-today": ("Today's newspaper ads,", "all in one place"),
    "02-detail": ("Read every clipping", "with the last date upfront"),
    "03-browse": ("Browse jobs, tenders,", "admissions and more"),
    "04-search": ("Search the archive", "by post, city or organisation"),
}


def frame(src: Path, lines):
    w, h = 1080, 1920
    img = Image.new("RGB", (w, h), NAVY)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(round(NAVY[i] + (NAVY_DARK[i] - NAVY[i]) * t) for i in range(3)))

    font = ImageFont.truetype(SERIF, 64)
    y = 90
    for i, line in enumerate(lines):
        tw = d.textlength(line, font=font)
        d.text(((w - tw) / 2, y), line, font=font, fill=AMBER if i == 1 else PAPER)
        y += 82

    shot = Image.open(src).convert("RGB")
    # Trim the emulator's 1-2px highlight border.
    shot = shot.crop((8, 8, shot.width - 8, shot.height - 8))
    sw = 740
    sh = round(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    x, top = (w - sw) // 2, 300

    radius = 44
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius=radius, fill=255)

    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x, top + 14, x + sw, top + sh + 14], radius=radius, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")
    img.paste(shot, (x, top), mask)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for n, src in enumerate(sorted(s for s in SRC.glob("*.png") if s.stem in CAPTIONS), start=1):
        lines = CAPTIONS[src.stem]
        out = OUT / f"{n}.png"
        frame(src, lines).save(out, optimize=True)
        print("wrote", out)


if __name__ == "__main__":
    main()

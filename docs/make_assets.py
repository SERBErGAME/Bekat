"""Phone mockups and crops from the real app screenshots (docs/shots/<lang>).
Run: python3 docs/make_assets.py"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
OUT = HERE / "assets"
OUT.mkdir(exist_ok=True)


def rounded(im, r):
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], r, fill=255)
    im = im.convert("RGBA")
    im.putalpha(m)
    return im


def phone(src, dst):
    shot = Image.open(src).convert("RGB")  # 824 x 1760
    w, h = shot.size
    bez, pad = 26, 70
    body_w, body_h = w + 2 * bez, h + 2 * bez
    canvas = Image.new("RGBA", (body_w + 2 * pad, body_h + 2 * pad), (0, 0, 0, 0))
    # shadow
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([pad, pad + 30, pad + body_w, pad + body_h + 30], 120, fill=(20, 30, 60, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(34))
    canvas.alpha_composite(sh)
    body = Image.new("RGBA", (body_w, body_h), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, body_w - 1, body_h - 1], 118, fill=(21, 23, 28, 255))
    ImageDraw.Draw(body).rounded_rectangle([3, 3, body_w - 4, body_h - 4], 115, outline=(70, 74, 84, 255), width=3)
    body.alpha_composite(rounded(shot, 92), (bez, bez))
    # camera dot
    ImageDraw.Draw(body).ellipse([body_w // 2 - 13, bez + 22, body_w // 2 + 13, bez + 48], fill=(12, 13, 16, 255))
    canvas.alpha_composite(body, (pad, pad))
    canvas.save(dst)


for lang in ("uz", "ru"):
    d = HERE / "shots" / lang
    for name in ("02_home", "03_scheme", "04_search", "05_plan", "06_trip"):
        phone(d / f"{name}.png", OUT / f"phone_{name}_{lang}.png")
    Image.open(d / "scheme_wide.png").crop((0, 150, 3000, 2200)).save(OUT / f"scheme_{lang}.png")
# city overview without the empty sky
Image.open(HERE / "shots" / "uz" / "map_city.png").crop((0, 260, 2400, 1760)).save(OUT / "map_city.png")
Image.open(HERE / "shots" / "uz" / "map_center.png").save(OUT / "map_center.png")
# cartoon bus from the splash screen (background is the app's #EEF1F6)
# bus.png: high-res crop of the splash screen (see README)
print("ok", sorted(p.name for p in OUT.iterdir()))

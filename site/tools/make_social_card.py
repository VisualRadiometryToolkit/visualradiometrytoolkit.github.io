# make_social_card.py — the 1200×630 link-preview image (og:image, twitter:card)
# of the landing page: the logo beside the site's name, tagline and URL.
#
#   pixi run social-card
#
# Writes ../icons/social-card.png. The text matches index.html's <title> and
# description; regenerate when either changes. The logo is drawn by
# make_icons.py's `logo_image` (no SVG rasterizer needed).
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from make_icons import logo_image

HERE = Path(__file__).resolve().parent
ICONS = HERE.parent / "icons"
W, H = 1200, 630
INK, MUTED, BG = (32, 33, 36), (95, 99, 104), (255, 255, 255)
TITLE = "Visual Radiometry Toolkit"
TAGLINE = ["Julia packages for radiometric camera",
           "models: vignetting, aperture, focus",
           "and sensor response"]
URL = "visualradiometrytoolkit.github.io"


def font(names, size):
    for n in names:
        for d in ("/usr/share/fonts/opentype/inter", "/usr/share/fonts/truetype/dejavu"):
            p = Path(d) / n
            if p.exists():
                return ImageFont.truetype(str(p), size)
    return ImageFont.load_default(size)


logo = logo_image(360)
card = Image.new("RGBA", (W, H), BG)
card.alpha_composite(logo, (60, (H - logo.height) // 2))
d = ImageDraw.Draw(card)
x = 60 + logo.width + 40
size = 60   # the largest title that fits the card with a 60 px margin
while d.textlength(TITLE, font=font(["Inter-Bold.otf", "DejaVuSans-Bold.ttf"], size)) > W - x - 60:
    size -= 2
d.text((x, 160), TITLE, font=font(["Inter-Bold.otf", "DejaVuSans-Bold.ttf"], size), fill=INK)
body = font(["Inter-Regular.otf", "DejaVuSans.ttf"], 30)
for i, line in enumerate(TAGLINE):
    d.text((x, 262 + 46 * i), line, font=body, fill=MUTED)
d.text((x, 452), URL, font=font(["Inter-Medium.otf", "DejaVuSans.ttf"], 30), fill=(154, 29, 22))
card.convert("RGB").save(ICONS / "social-card.png", optimize=True)
print("wrote", ICONS / "social-card.png")

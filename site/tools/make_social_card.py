# make_social_card.py — the 1200×630 link-preview image (og:image, twitter:card)
# of the landing page: the logo beside the site's name, tagline and URL.
#
#   site/fetch_shared.sh
#   pixi run --manifest-path site/.shared/tools/pixi.toml python site/tools/make_social_card.py
#
# Writes ../icons/social-card.png. The text matches index.html's <title> and
# description; regenerate when either changes. The logo is drawn by
# make_icons.py's `logo_image` (no SVG rasterizer needed); the card's layout is
# the stack's (stack_social_card.py, the Visual Geometry Toolkit site's, used at
# the commit pinned in site/SHARED_REF and never copied).
from make_icons import OUT, logo_image   # also puts the shared tools on the path

from stack_social_card import social_card

TITLE = "Visual Radiometry Toolkit"
TAGLINE = ["Julia packages for radiometric camera",
           "models: vignetting, aperture, focus",
           "and sensor response"]
URL = "visualradiometrytoolkit.github.io"

social_card(OUT / "social-card.png", logo_image(360), TITLE, TAGLINE, URL, (154, 29, 22))

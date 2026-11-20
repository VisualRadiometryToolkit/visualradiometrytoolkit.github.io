"""Build the site's icons into ../icons.

    site/fetch_shared.sh
    pixi run --manifest-path site/.shared/tools/pixi.toml python site/tools/make_icons.py

The tile every package icon is drawn on (a 96x96 SVG; light and dark colours
switched inside the file with prefers-color-scheme, so an icon works as an
<img>, as a mermaid image node, and as the favicon) and the Python environment
are the Visual Geometry Toolkit site's, used from its repository at the commit
pinned in site/SHARED_REF (site/fetch_shared.sh) and never copied: this file
holds only this site's icons, as data for that generator, and its logo.

Written here:
  vrc.svg            VisualRadiometryToolkitCore (a lens aperture of seven blades and a ray through it)
  vrio.svg           VisualRadiometryToolkitIO (a data file holding a falloff curve, data in and out)
  vrt_logo.svg       the toolkit's logo: the aperture of the title banner's eye (seven blades, the banner's colours)
  favicon-32.png, favicon-64.png   the logo, drawn with Pillow from the same geometry (no SVG rasterizer needed)

Fetched from the Visual Geometry Toolkit's site by site/fetch_shared.sh (untracked here; never edited):
  vgt_logo.svg       the Visual Geometry Toolkit's logo (the foundation node and card)
  radiometric.svg    Real Cameras are Radiometric / RadiometricCamera
"""
import math, pathlib, sys
from PIL import Image, ImageDraw

SITE = pathlib.Path(__file__).resolve().parent.parent
SHARED = SITE / ".shared" / "tools"
SHARED.is_dir() or sys.exit("site/.shared is missing: run site/fetch_shared.sh first")
sys.path.insert(0, str(SHARED))
from stack_icons import arrow, svg, write_icons   # the stack's tile (the Visual Geometry Toolkit site's)

OUT = SITE / "icons"

# The aperture of the title banner (site/main.js): N = 7 blades, the pupil a heptagon of circumradius `rp`, each blade
# from one side of the pupil out to the rim `R`, turned by `rot`.
N, ROT = 7, 0.21

def pupil(cx, cy, rp):
    return [(cx + rp * math.cos(ROT + k / N * 2 * math.pi), cy + rp * math.sin(ROT + k / N * 2 * math.pi)) for k in range(N)]

def blade_edges(cx, cy, rp, R, lead=0.55):
    """One line per blade: from a pupil vertex out to the rim, leading the vertex by `lead` radians."""
    return [((x, y), (cx + R * math.cos(ROT + k / N * 2 * math.pi + lead), cy + R * math.sin(ROT + k / N * 2 * math.pi + lead)))
            for k, (x, y) in enumerate(pupil(cx, cy, rp))]

icons = {}

# VisualRadiometryToolkitCore: the aperture, and one ray of light through its pupil
body = '<circle class="s" cx="48" cy="48" r="32"/>'
body += '<path class="s" d="' + " ".join(f"M{a[0]:.1f},{a[1]:.1f} L{b[0]:.1f},{b[1]:.1f}" for a, b in blade_edges(48, 48, 13, 32)) + '"/>'
body += '<polygon class="a" points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in pupil(48, 48, 13)) + '"/>'
body += '<circle class="fa" cx="48" cy="48" r="4"/>'
icons["vrc"] = ("VisualRadiometryToolkitCore.jl", body)

# VisualRadiometryToolkitIO: a data file holding a radial profile (a falloff curve), with data in and out
icons["vrio"] = ("VisualRadiometryToolkitIO.jl",
    '<path class="s" d="M34,18 H56 L66,28 V78 H34 Z M56,18 V28 H66"/>'
    + '<path class="a" d="M41,44 C50,44 53,50 59,66"/>'
    + arrow(8, 36, 26, 36) + arrow(72, 64, 90, 64))

write_icons(icons, OUT)

# The logo: the banner's aperture on its dark red ground.
BG, RIM, BLADES, EDGE, PUPIL, GLINT = "#2a0709", "#9a1d16", ("#5a0d12", "#3a0808"), "#ff6a46", "#050101", "#fff6ef"
C, R, RP = 256, 228, 92

def logo_blades():
    """Each blade as a polygon: its side of the pupil, then out along the rim to the next blade's leading edge."""
    p = pupil(C, C, RP); out = []
    for k in range(N):
        a0 = ROT + k / N * 2 * math.pi + 0.55; a1 = ROT + (k + 1) / N * 2 * math.pi + 0.55
        arc = [(C + R * math.cos(a0 + (a1 - a0) * i / 12), C + R * math.sin(a0 + (a1 - a0) * i / 12)) for i in range(13)]
        out.append([p[k]] + arc + [p[(k + 1) % N]])
    return out

pts = lambda q: " ".join(f"{x:.1f},{y:.1f}" for x, y in q)
logo = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">',
        "<!-- VisualRadiometryToolkit: a lens aperture of seven blades, the iris of the title banner's eye; the light a",
        "     camera collects passes through it. Written by site/tools/make_icons.py. -->",
        f'<circle cx="{C}" cy="{C}" r="250" fill="{BG}"/>', f'<circle cx="{C}" cy="{C}" r="{R}" fill="{RIM}"/>']
for k, q in enumerate(logo_blades()):
    logo.append(f'<polygon points="{pts(q)}" fill="{BLADES[k % 2]}" stroke="{EDGE}" stroke-width="5" stroke-linejoin="round"/>')
logo += [f'<polygon points="{pts(pupil(C, C, RP))}" fill="{PUPIL}" stroke="{EDGE}" stroke-width="5" stroke-linejoin="round"/>',
         f'<circle cx="{C}" cy="{C}" r="{R}" fill="none" stroke="{BG}" stroke-width="10"/>',
         f'<circle cx="{C - 84}" cy="{C - 92}" r="26" fill="{GLINT}" fill-opacity="0.9"/>', "</svg>"]
(OUT / "vrt_logo.svg").write_text("\n".join(logo) + "\n")

def logo_image(size, ss=4):
    """The logo as an RGBA image of `size` pixels, drawn at `ss` times the size and reduced."""
    n = size * ss; k = n / 512
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    sc = lambda q: [(x * k, y * k) for x, y in q]
    disc = lambda r, fill: d.ellipse([(C - r) * k, (C - r) * k, (C + r) * k, (C + r) * k], fill=fill)
    disc(250, BG); disc(R, RIM)
    for i, q in enumerate(logo_blades()):
        d.polygon(sc(q), fill=BLADES[i % 2]); d.line(sc(q + q[:1]), fill=EDGE, width=max(1, round(5 * k)), joint="curve")
    d.polygon(sc(pupil(C, C, RP)), fill=PUPIL)
    p = pupil(C, C, RP); d.line(sc(p + p[:1]), fill=EDGE, width=max(1, round(5 * k)), joint="curve")
    d.ellipse([(C - R) * k, (C - R) * k, (C + R) * k, (C + R) * k], outline=BG, width=max(1, round(10 * k)))
    d.ellipse([(C - 84 - 26) * k, (C - 92 - 26) * k, (C - 84 + 26) * k, (C - 92 + 26) * k], fill=GLINT)
    return im.resize((size, size), Image.LANCZOS)

if __name__ == "__main__":
    for size in (32, 64):
        logo_image(size).save(OUT / f"favicon-{size}.png", optimize=True)
    for p in sorted(OUT.iterdir()):
        print(p.name, p.stat().st_size)

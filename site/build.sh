#!/usr/bin/env bash
# Assembles the whole site into one tree, the one .github/workflows/Site.yml deploys:
#   <out>/               the landing page (site/index.html, style.css, main.js, icons/) with the tooling it shares
#                        with the Visual Geometry Toolkit's site (shared/ and two icons, fetched at the commit pinned
#                        in site/SHARED_REF by site/fetch_shared.sh; never tracked here)
#   <out>/<Package>/     each package's documentation, every published version (site/portal/make.jl: MultiDocumenter
#                        over this repository's gh-pages branch, or over PORTAL_LOCAL=<dir> holding <Package>/ builds)
# Usage: site/build.sh [out]   (default site/build). Instantiate site/portal first (README.md).
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out=$(realpath -m "${1:-$root/site/build}")
julia=${JULIA:-julia}

"$root/site/fetch_shared.sh"

# The portal first: it writes <out> and a root redirect, which the landing page replaces.
rm -rf "$out"
PORTAL_OUT="$out" "$julia" --color=yes --startup-file=no --project="$root/site/portal" "$root/site/portal/make.jl"
cp -r "$root/site/index.html" "$root/site/style.css" "$root/site/main.js" "$root/site/shared" "$root/site/icons" "$out/"
touch "$out/.nojekyll"   # GitHub Pages serves the files as they are (no Jekyll pass)

# The landing page is there with what it loads, and every package docs it links to exists (when the portal has any).
for f in index.html style.css main.js shared/base.css shared/site.js icons/vrt_logo.svg icons/vgt_logo.svg icons/radiometric.svg icons/social-card.png; do
    [ -s "$out/$f" ] || { echo "site/build.sh: $f missing in $out" >&2; exit 1; }
done
grep -q 'class="iris-banner' "$out/index.html" || { echo "site/build.sh: index.html is not the landing page" >&2; exit 1; }
for d in "$out"/VisualRadiometryToolkit*/; do
    [ -d "$d" ] || continue
    p=$(basename "$d")
    grep -q "https://visualradiometrytoolkit.github.io/$p/" "$out/index.html" ||
        { echo "site/build.sh: the landing page does not link to the docs of $p" >&2; exit 1; }
done
echo "site/build.sh: the site is in $out"

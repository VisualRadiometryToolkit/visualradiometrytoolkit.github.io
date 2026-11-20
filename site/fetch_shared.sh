#!/usr/bin/env bash
# The landing-page tooling this site shares with the Visual Geometry Toolkit's, taken from ITS repository at the
# commit pinned in site/SHARED_REF. Nothing of it is tracked here:
#   site/.shared/                  the pinned checkout (tools/: the icon and social-card generators and their pixi
#                                  environment, which site/tools/*.py import and run in; portal/stack_portal.jl:
#                                  the portal builder, which site/portal/make.jl includes)
#   site/portal/Project.toml       the portal's Julia environment
#   site/shared/                   base.css and site.js, which index.html links before this site's own style.css and
#                                  main.js
#   site/icons/vgt_logo.svg,
#   site/icons/radiometric.svg     the canonical copies of the two icons this page shows
# Usage: site/fetch_shared.sh      (site/build.sh runs it; run it once before a local preview or `pixi run`)
#   SHARED_SRC=<a local checkout of that repository>   use its working tree instead of fetching (to try a change
#                                                      there before it is pinned here)
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=https://github.com/VisualGeometryToolkit/visualgeometrytoolkit.github.io.git
ref=$(grep -v '^#' "$here/SHARED_REF" | tr -d '[:space:]')
[[ "$ref" =~ ^[0-9a-f]{40}$ ]] || { echo "fetch_shared.sh: site/SHARED_REF does not hold a full commit hash" >&2; exit 1; }
dst=$here/.shared
if [ -n "${SHARED_SRC:-}" ]; then
    rm -rf "$dst"; mkdir -p "$dst"
    cp -r "$SHARED_SRC/shared" "$SHARED_SRC/tools" "$SHARED_SRC/icons" "$dst/"
    mkdir -p "$dst/portal"; cp "$SHARED_SRC/portal/stack_portal.jl" "$SHARED_SRC/portal/Project.toml" "$dst/portal/"
    rm -rf "$dst/tools/.pixi"
elif [ "$(git -C "$dst" rev-parse -q --verify HEAD 2>/dev/null || true)" != "$ref" ] || [ "$(git -C "$dst" rev-parse --show-toplevel 2>/dev/null)" != "$dst" ]; then
    rm -rf "$dst"; git init -q "$dst"
    git -C "$dst" fetch -q --depth 1 "$repo" "$ref"
    git -C "$dst" -c advice.detachedHead=false checkout -q FETCH_HEAD
fi
rm -rf "$here/shared"; cp -r "$dst/shared" "$here/shared"
cp "$dst/icons/vgt_logo.svg" "$dst/icons/radiometric.svg" "$here/icons/"
cp "$dst/portal/Project.toml" "$here/portal/Project.toml"
for f in shared/base.css shared/site.js icons/vgt_logo.svg icons/radiometric.svg portal/Project.toml .shared/portal/stack_portal.jl \
         .shared/tools/stack_icons.py .shared/tools/stack_social_card.py .shared/tools/pixi.toml; do
    [ -s "$here/$f" ] || { echo "fetch_shared.sh: $f missing at $ref" >&2; exit 1; }
done
echo "fetch_shared.sh: the shared site tooling at ${SHARED_SRC:-$ref}"

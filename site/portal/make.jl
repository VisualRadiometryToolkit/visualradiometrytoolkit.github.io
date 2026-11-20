# The Visual Radiometry Toolkit's documentation portal.
#
# Aggregates the per-package Documenter sites into one site with a shared
# navigation bar and cross-package search (MultiDocumenter). The workspace
# packages are read from ONE shallow clone of this repository's gh-pages branch
# (gh-pages/<Package>/…, where .github/workflows/Site.yml deploys them).
#
#   julia --project=site/portal site/portal/make.jl                     # clone gh-pages, build site/portal/out/
#   PORTAL_LOCAL=<dir> julia --project=site/portal site/portal/make.jl  # <dir>/<Package>/ holds local builds
#   PORTAL_OUT=<dir> …                                                  # output directory (default site/portal/out)
#
# site/build.sh then copies the hand-written landing page (index.html,
# style.css, main.js, icons/) over the output's root redirect.
#
# Portal paths are the package names, so a package's docs are at /<Package>/.

using TOML
# portal_pages, portal_docs, portal_out, make_portal: the Visual Geometry Toolkit site's portal builder, used from its
# repository at the commit pinned in site/SHARED_REF (site/fetch_shared.sh) and never copied; this folder's
# Project.toml comes the same way.
include(joinpath(@__DIR__, "..", ".shared", "portal", "stack_portal.jl"))

const ROOT = dirname(dirname(@__DIR__))
const REPO = "https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io.git"
const WORKSPACE = TOML.parsefile(joinpath(ROOT, "Project.toml"))["workspace"]["projects"]   # every member is a package (WORKSPACE.toml: no tooling member)
# The foundation's documentation: a navbar link, never a second copy.
const LINKS = ["Visual Geometry Toolkit" => "https://visualgeometrytoolkit.github.io/"]

# no gh-pages branch yet (before the first docs deploy): the portal has no package docs, the landing page stands alone
pages = portal_pages(REPO; required = false)
make_portal(portal_out(joinpath(@__DIR__, "out")), portal_docs(pages, WORKSPACE, LINKS);
    canonical_domain = "https://visualradiometrytoolkit.github.io/")

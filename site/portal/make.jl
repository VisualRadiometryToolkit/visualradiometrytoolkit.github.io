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

using MultiDocumenter
using TOML

const ROOT = dirname(dirname(@__DIR__))
const REPO = "https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io.git"
const WORKSPACE = TOML.parsefile(joinpath(ROOT, "Project.toml"))["workspace"]["projects"]   # every member is a package (WORKSPACE.toml: no tooling member)
# The foundation's documentation: a navbar link, never a second copy.
const LINKS = ["Visual Geometry Toolkit" => "https://visualgeometrytoolkit.github.io/"]

outpath = get(ENV, "PORTAL_OUT", joinpath(@__DIR__, "out"))
pages = get(ENV, "PORTAL_LOCAL", "")
if isempty(pages)
    pages = mktempdir()
    # no gh-pages branch yet (before the first docs deploy): the portal has no package docs
    success(pipeline(`git clone -q --depth 1 --branch gh-pages $REPO $pages`; stderr = devnull)) ||
        @warn "no gh-pages branch at $REPO: the portal holds no package docs"
end

docs = MultiDocumenter.DropdownComponent[]
for p in WORKSPACE
    isdir(joinpath(pages, p)) || (@warn "no docs for $p under $pages"; continue)
    push!(docs, MultiDocumenter.MultiDocRef(; upstream = joinpath(pages, p), path = p, name = p))
end
foreach(((name, url),) -> push!(docs, MultiDocumenter.Link(name, url)), LINKS)

if any(d -> d isa MultiDocumenter.MultiDocRef, docs)
    MultiDocumenter.make(
        outpath, docs;
        search_engine = MultiDocumenter.SearchConfig(index_versions = ["stable", "dev"], engine = MultiDocumenter.FlexSearch),
        rootpath = "/",
        canonical_domain = "https://visualradiometrytoolkit.github.io/",
        sitemap = true,
    )
else
    mkpath(outpath)   # the landing page alone
end

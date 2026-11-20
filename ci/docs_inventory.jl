# docs_inventory.jl — included by the docs/make.jl of the packages that link to other packages' docs: the inventories
# for DocumenterInterLinks.
#
#   vgtk_inventory(p)   a Visual Geometry Toolkit package `p` (VisualGeometryToolkitCore, …): its published `dev` docs'
#                       objects.inv. The stack conventions live THERE (VisualGeometryToolkitCore's Conventions page); a
#                       page here links to them with @extref and never restates them.
#   vrtk_inventory(p)   a package `p` of this workspace: the published `dev` docs' objects.inv; with VRTK_DOCS_LOCAL=1
#                       this checkout's own build of `p` where one exists, so a release's docs build before its
#                       dependencies' docs are published.
#
# `vrtk_docs_local()` is the one reader of VRTK_DOCS_LOCAL, and `vrtk_local_linkcheck_ignore()` its linkcheck rule: in a
# local build an @extref into a sibling package built here points at anchors not yet published, so the published docs'
# URLs are not link-checked.
vgtk_inventory(p) = "https://visualgeometrytoolkit.github.io/$p/dev/"
vrtk_docs_local() = get(ENV, "VRTK_DOCS_LOCAL", "") == "1"
vrtk_local_linkcheck_ignore() = vrtk_docs_local() ? [r"^https://visualradiometrytoolkit\.github\.io/"] : Regex[]
vrtk_inventory(p) = (url = "https://visualradiometrytoolkit.github.io/$p/dev/";
    inv = joinpath(@__DIR__, "..", p, "docs", "build", "objects.inv");
    vrtk_docs_local() && isfile(inv) ? (url, inv) : url)

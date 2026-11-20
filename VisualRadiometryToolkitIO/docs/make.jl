# The documentation site: a hand-written manual (docs/src/index.md) and an @autodocs API reference (docs/src/api.md). Build locally:
#
#   julia --project=docs --startup-file=no docs/make.jl     # → docs/build/index.html
#
# `checkdocs = :public` with no `warnonly`: a public docstring missing from an
# API page, a broken cross-reference, a dead link or a failing doctest stops
# the build.

using Documenter
using VisualRadiometryToolkitIO

DocMeta.setdocmeta!(
    VisualRadiometryToolkitIO, :DocTestSetup,
    :(using VisualRadiometryToolkitIO);
    recursive = true,
)

makedocs(;
    modules = [VisualRadiometryToolkitIO],
    authors = "Ties Harder, Felix Seegräber, James Pritts",
    sitename = "VisualRadiometryToolkitIO.jl",
    repo = Documenter.Remotes.GitHub("VisualRadiometryToolkit", "visualradiometrytoolkit.github.io"),
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/",
        edit_link = "main",
    ),
    # The docs gates of the stack: every public docstring is in the manual, the
    # doctests run, every external link resolves, and nothing is warnonly — a
    # warning fails the build.
    checkdocs = :public,
    doctest = true,
    linkcheck = true,
    # Rate-limited hosts that answer a crawler with 403/429 (lychee,
    # .github/workflows/Links.yml, checks them with a token), and this site's
    # own pages, which a first build precedes.
    linkcheck_ignore = [r"^https://github\.com/", r"^https://visualradiometrytoolkit\.github\.io"],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo = "github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io.git",
    dirname = "VisualRadiometryToolkitIO",
    tag_prefix = "VisualRadiometryToolkitIO-",
    devbranch = "main",
    push_preview = false,
)

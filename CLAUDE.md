# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code anywhere in this repository. Each package directory has its own
`CLAUDE.md` with what is specific to it; read both.

## The repository

This repository is the Visual Radiometry Toolkit: its packages AND its site.
It is a Julia 1.13 **workspace** of separately registered packages, one
directory each (the directory name is the package name, the registration
`subdir`, the TagBot tag prefix `<Name>-v…` and the docs `dirname`), with the
landing page and documentation portal beside them. Its name,
`visualradiometrytoolkit.github.io`, makes GitHub Pages serve it at
<https://visualradiometrytoolkit.github.io>.

| directory | what | depends on (stack) |
|---|---|---|
| `VisualRadiometryToolkitCore/` | the types of a radiometric camera: a geometric camera and its radiometric parts | VisualGeometryToolkitCore |
| `VisualRadiometryToolkitIO/` | file formats of the radiometric types | VisualRadiometryToolkitCore, VisualGeometryToolkitCore, VisualGeometryToolkitIO |
| `ci/` | workspace tooling; a workspace member, never registered | VisualGeometryToolkitCore |
| `site/` | the landing page (`index.html`, `style.css`, `main.js`, `icons/`), its icon tooling (`tools/`) and the docs portal (`portal/`); not Julia package code | — |
| `docs/design/` | design notes of the workspace (the migration inventory) | — |

**Radiometry lifts geometry.** The toolkit extends the
[Visual Geometry Toolkit](https://github.com/VisualGeometryToolkit/VisualGeometryToolkit.jl)
(VGTK): a package here may depend on VGTK packages; no VGTK package may depend
on a package here. The stack dependency law is VGTK's allow-list with this
repository's rows, `VisualRadiometryToolkitCore/configs/stack_dependencies.toml`;
nothing else may name a stack package.

The root `Project.toml` is not a package. Its `[sources]` resolve every package
of this repository to its directory, and its `[workspace]` lists them and `ci`;
each package's own `[workspace]` adds its `test/` and `docs/` environments.
VGTK packages are NOT sourced: they come from the registry, as a user gets
them. There is ONE Manifest, at the root, and it is never tracked.

## Commands

```bash
# Once per clone
git config core.hooksPath .githooks          # re-resolve the root Manifest when any Project.toml moves
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Test one package (inside the workspace: no sandbox, the root Manifest)
julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test()'
julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test(; test_args = ["vignetting"])'
julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test(; julia_args = ["--depwarn=error"])'

# Docs of one package. --startup-file=no is required (a startup.jl that
# activates another env overrides --project).
julia --project=VisualRadiometryToolkitCore/docs --startup-file=no VisualRadiometryToolkitCore/docs/make.jl

# Workspace checks (CI runs them on every PR)
julia --project=ci ci/registration_lint.jl   # versions, compat, names, no tracked Manifest, allow-list
julia --project=ci ci/agent_docs.jl          # the agent-docs policy over every tracked agent file
julia --startup-file=no ci/affected.jl origin/main HEAD   # packages a change touches, with dependents

# The site, as CI assembles it (the portal over the published package docs, the landing page at its root)
julia --project=site/portal -e 'using Pkg; Pkg.instantiate()'
site/build.sh site/build
```

Test dependencies live in `<Package>/test/Project.toml` (no `[extras]`/`[targets]`).
The quality gates (Aqua, ExplicitImports, JET, naming, duplication, docstrings,
the stack contracts) are VisualGeometryToolkitCore's; a package's suite calls
them and holds no copy. See `RELEASING.md` for releases.

## The site

`site/` is plain static HTML, CSS and JavaScript, with the structure of the
Visual Geometry Toolkit's landing page. The title banner is an approved design:
its CSS (`style.css`, the `.iris-*` rules) and drawing script (`main.js`, the
last block) are changed only at the owner's request. `site/icons/` is written
by `site/tools/make_icons.py` (except the two icons its header names); do not
edit the SVGs by hand. `.github/workflows/Site.yml` is the one deploy: package
docs into `gh-pages/<Package>/` (the versioned store), then `site/build.sh`
assembles the portal and the landing page into the tree GitHub Pages serves.

## Privacy boundary

This repository is public, and so is everything in it: code, comments,
docstrings, documentation, design notes, the site, commit messages, branch
names, issue and pull-request text.

- **No unpublished research.** Nothing enters this repository that is not
  already public in a published paper, a public preprint or a released package:
  no method, model, result, dataset, experiment, plan or name of work that is
  in preparation, under review or intended for a future publication. This
  holds for stubs, placeholders, commented-out code, TODO notes and "planned"
  lists as much as for working code.
- **Extension points are described generically.** A design may say that a part
  can be extended or that a type hierarchy is open; it never says with what
  unpublished thing.
- **When in doubt, leave it out and ask the owner.** If a task seems to need
  unpublished material here, stop: that work belongs in a private repository
  that depends on this one.
- No private paths, machine names, credentials or correspondence
  (`ci/agent_docs.jl` checks the agent files for the public patterns).

A change that would cross this boundary is refused, whoever asks for it.

## Git commit conventions

- Never add "Co-Authored-By: Claude" or any other AI attribution to a commit message.
- Never add a "Generated with Claude Code" footer.
- A commit that changes several packages names each of them.
- Never commit a Manifest or anything under `.claude/`.

## Stack conventions

The conventions (naming, signatures, data arguments, frames, pixel origins,
bearings, residuals and distances, Jacobians, units, the stack contracts) are
the Visual Geometry Toolkit's. The canonical text lives once, in
`VisualGeometryToolkitCore/conventions/` of the VGTK repository, and ships with
VisualGeometryToolkitCore (`VisualGeometryToolkitCore.conventions_dir()`).
This repository follows it and carries no copy: read it there, change it there
and nowhere else.

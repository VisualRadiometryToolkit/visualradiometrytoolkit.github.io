docs-pass: 73f8075
landing: this repository's `site/` (its "Get started" lead names the packages' version: 0.1.2)

# VisualRadiometryToolkitCore 0.1.2, VisualRadiometryToolkitIO 0.1.2 docs review (the Core 0.14 solve branch)

On VisualGeometryToolkitCore "0.14" and VisualGeometryToolkitIO "0.12" in both packages and their test/ and docs/
projects. No public name, signature or docstring changed. The one example (README and manual Home page of
VisualRadiometryToolkitCore) builds its pinhole lens as `Lens(Perspective())`, the retired alias `Pinhole` gone; the
README tests run it in a fresh environment. The CHANGELOGs name the release. Searched: the READMEs, the docs pages,
the guides and the site for `Pinhole`, the setters' bodies and a VisualGeometryToolkit version. Both manuals build
with checkdocs, doctests and linkcheck, no warning.

---

docs-pass: fa66cb0
landing: this repository's `site/` (read, not edited: its cards and install lines name no VisualGeometryToolkit version)

# VisualRadiometryToolkitCore 0.1.1, VisualRadiometryToolkitIO 0.1.1 docs review

Compat only (7b83647): VisualGeometryToolkitCore "0.13", VisualGeometryToolkitIO "0.11.1" in both packages and their
test/ and docs/ projects; no public name, docstring, page or example changed. The CHANGELOGs name the release. Searched:
the README, the docs pages and the site for a VisualGeometryToolkit version (only docs/design/inventory.md's history,
which stays).

Then fa66cb0: the tests use VisualGeometryToolkitCore's `thrown_message` and VisualGeometryToolkitIO's `nested_roundtrip` and
`edited_copy` (the upstream duplication gate's four findings); VisualGeometryToolkitIO's compat floor 0.11.2; the CHANGELOGs
say so. No docstring or page changed.

---

docs-pass: cb60c54
landing: this repository's `site/` (read, not edited). `site/index.html` needs: the two cards' install lines ("Under construction (0.0.1) · not registered yet") replaced by `pkg> add VisualRadiometryToolkitCore` and `pkg> add VisualRadiometryToolkitIO`; the "Get started" lead ("under construction: its packages are skeletons at a placeholder version and are not in a registry yet") replaced by the install line; the tagline, the three description meta tags and the VisualRadiometryToolkitCore card name a fourth camera part that the package does not have and say "each part an abstract type whose default is absent" — the parts are the focus surface, the aperture radius and the vignetting, and only the vignetting has an absent default.

# VisualRadiometryToolkitCore 0.1.0, VisualRadiometryToolkitIO 0.1.0 docs review — branch migration

The first release of both packages and their first registration in General. There is no earlier docs release, so the
review covers every page. The record itself is the only change after cb60c54 (`.release/` is outside the gate).

## 1. Public API

A first release: every public name is new. VisualRadiometryToolkitCore exports `AbstractVignetting`, `NoVignetting`,
`TensorProductVignetting`, `RadialVignetting`, `LogVignetting`, `EnvironmentLight`, `SphericalHarmonicMap`,
`RadiometricCameraModel`, `TexturedTarget`; the rest is `public` (the lists in `src/VisualRadiometryToolkitCore.jl`).
VisualRadiometryToolkitIO exports nothing; its eight public names are the three kinds, the three body tables,
`migrate_vignetting_body` and `json_schemas`, and it adds methods to VisualGeometryToolkitIO's `load` and `save`.

## 2. What changed in this pass

- Project files: the temporary git sources of VisualGeometryToolkitCore and VisualGeometryToolkitIO removed from the
  root and from both packages' Project.toml, test/Project.toml and docs/Project.toml; VisualGeometryToolkitIO removed
  from the root `[deps]` (VisualGeometryToolkitCore stays: the workspace checks run in the root project).
  VisualRadiometryToolkitIO's Project.toml has no `[sources]`, and its test and docs projects source the package
  itself only: the registration lint refuses any other source, and the root's `[sources]` resolve the sibling.
  Versions 0.1.0; VisualRadiometryToolkitIO's compat on VisualRadiometryToolkitCore is "0.1".
- CHANGELOGs: the first sections are `## 0.1.0`, state what each package holds and where it came from. Core's gained
  the entry for what came from VisualGeometryToolkitCore (it was missing) and lost two false statements
  (`NoVignetting` subtyping VisualGeometryToolkitCore's abstract type; `inverse_focus_distance` at a chief direction).
- READMEs (root and both packages): no "under construction", "skeleton" or placeholder statement; the root README
  names three camera parts; each package README has the six parts of the stack's template (purpose, install line,
  one example, documentation links, citation, licence) and a coverage badge.
- Landing pages: the same install line and the same example as the README; "What it provides"; a documentation list.
- VisualRadiometryToolkitCore's Design page: the table of parts states what the camera has (a geometric camera, a
  focus surface, an aperture radius without a default, a vignetting whose default is `NoVignetting`); the rows and
  sentences about parts and defaults the package does not have are removed, and so is the sentence about a later
  package.
- VisualRadiometryToolkitIO's manual: a guide page, "The kinds" (the table of kinds, where they came from, embedding
  a body), so the manual is a landing page, a guide and an API reference.
- Agent docs (both packages' CLAUDE.md): no placeholder statement; Core's rule about parts states the vignetting.
- RELEASING.md: the packages are registered in General from their subdirectories.
- Tests: `test/readme_tests.jl` in both packages (VisualGeometryToolkitCore's `test_readme_example`: the README's
  block and install line, the landing page showing the same, the block run in a fresh environment).

## 3. Gates

Fresh clone at cb60c54, the workspace resolved from General and the in-repository paths, suite and docs build, on two
node types. VisualGeometryToolkitCore v0.12.0 and VisualGeometryToolkitIO v0.11.0 resolved from the registry.

| package | node type | suite | docs |
|---|---|---|---|
| VisualRadiometryToolkitCore | B200 | 3442 pass, 2 broken, 0 fail, 0 error | pass |
| VisualRadiometryToolkitCore | RTX | 3442 pass, 2 broken, 0 fail, 0 error | pass |
| VisualRadiometryToolkitIO | B200 | 214 pass, 1 broken, 0 fail, 0 error | pass |
| VisualRadiometryToolkitIO | RTX | 214 pass, 1 broken, 0 fail, 0 error | pass |

Registration lint (`stack_ci registration-lint`, the first-registration rules): 2 packages, 0 errors, 0 warnings.
Agent docs (`stack_ci agent-docs`): 0 findings.

## 4. Open

- `docs/design/inventory.md` on `main` describes the design before the migration and is not corrected here.
- The README's documentation links and badge point at the `dev` docs: `stable` exists only after TagBot's first tag.
  A "Docs: stable" badge and `stable` links follow the first tag.
- The General preflight script was not run (it calls a local Julia); its items were read by hand.

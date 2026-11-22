<p align="center"><img src="site/icons/vrt_logo.svg" width="160" alt="VisualRadiometryToolkit logo"></p>

# Visual Radiometry Toolkit

Julia packages for radiometric camera models: what decides how much light a
pixel collects (vignetting, aperture, focus), as types that lift the cameras
of the
[Visual Geometry Toolkit](https://visualgeometrytoolkit.github.io). Radiometry
lifts geometry: the toolkit depends on the Visual Geometry Toolkit and follows
its conventions; nothing there depends on it. The camera model is that of
[Real Cameras are Radiometric](https://arxiv.org/abs/2611.25265).

This repository is a Julia workspace and the toolkit's site in one. Each
package directory is a separately registered package with its own version,
tests and documentation; `site/` is the landing page and documentation portal
served at <https://visualradiometrytoolkit.github.io>.

| Package | Role | Docs |
|---|---|---|
| [VisualRadiometryToolkitCore](VisualRadiometryToolkitCore) | The radiometric camera (a geometric camera with its focus surface, aperture radius and vignetting), the vignetting fields, the sensor's quadrature rules, and the scene: an environment light, a Cook–Torrance material and a textured planar target | [docs](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/) |
| [VisualRadiometryToolkitIO](VisualRadiometryToolkitIO) | File formats: vignetting fields, environment lights and measured radial profiles as self-describing files, in the Visual Geometry Toolkit's envelope | [docs](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/) |

| Directory | What |
|---|---|
| [site](site) | The landing page, its icon tooling and the documentation portal |
| [docs/design](docs/design) | Design notes: the [inventory](docs/design/inventory.md) of the migration from VisualGeometryToolkitCore, VisualGeometryToolkitIO and RadiometricCamera |

## Installation

```julia-repl
pkg> add VisualRadiometryToolkitCore VisualRadiometryToolkitIO
```

Julia 1.13 or later. Every dependency is in the General registry. The
packages' own registration in General is pending; until it is merged, `add`
takes this repository's URL and the package's directory, as in
`https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io:VisualRadiometryToolkitCore`.
Each package's README has an example.

## Working in the repository

```bash
git clone https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io
cd visualradiometrytoolkit.github.io
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using VisualGeometryToolkitCore; VisualGeometryToolkitCore.install_githooks()'
julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test()'
```

Julia 1.13. [CLAUDE.md](CLAUDE.md) lists the commands and the rules (among
them the privacy boundary: the repository is public, and nothing unpublished
enters it); [RELEASING.md](RELEASING.md) states how packages are released.

The workspace tooling is the Visual Geometry Toolkit's, called and never
copied: the CI checks are VisualGeometryToolkitCore's
`stack_ci` with this repository's parameters in [WORKSPACE.toml](WORKSPACE.toml),
the workflows call its reusable workflows, the git hooks are its
`install_githooks`, and the landing page takes its stylesheet base, script and
icon generators from the Visual Geometry Toolkit site's repository at the
commit pinned in [site/SHARED_REF](site/SHARED_REF).

To preview the landing page: `site/fetch_shared.sh` (once, and after the pin
moves), then `python -m http.server` in `site/` and open
<http://localhost:8000>. `site/icons/` is generated:

```bash
site/fetch_shared.sh
pixi run --manifest-path site/.shared/tools/pixi.toml python site/tools/make_icons.py
pixi run --manifest-path site/.shared/tools/pixi.toml python site/tools/make_social_card.py
```

## Citing

```bibtex
@article{harder2026radiometric,
  author        = {Harder, Ties and Seegr{\"a}ber, Felix and Nakath, David and
                   Sauer, Hendrik and K{\"o}ser, Kevin and Pritts, James},
  title         = {Real Cameras are Radiometric},
  journal       = {arXiv preprint arXiv:2611.25265},
  year          = {2026},
  eprint        = {2611.25265},
  archivePrefix = {arXiv},
  primaryClass  = {cs.CV},
}
```

## License

MIT. See [LICENSE](LICENSE) and [AUTHORS.md](AUTHORS.md).

# VisualRadiometryToolkitIO.jl

[![CI](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/dev/)
[![Coverage](https://codecov.io/gh/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/branch/main/graph/badge.svg?flag=VisualRadiometryToolkitIO)](https://app.codecov.io/gh/VisualRadiometryToolkit/visualradiometrytoolkit.github.io?flags%5B0%5D=VisualRadiometryToolkitIO)

VisualRadiometryToolkitIO saves and loads the vignetting fields, environment
lights and measured radial profiles of
[VisualRadiometryToolkitCore](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/)
as self-describing JSON files, and a value read back from a file equals the
value that was written. The files use the envelope and the schema rules of
[VisualGeometryToolkitIO](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitIO/):
each file declares its units and conventions, and every earlier schema version
a published file holds still loads.

## Installation

```julia-repl
pkg> add VisualGeometryToolkitIO VisualRadiometryToolkitCore VisualRadiometryToolkitIO StaticArrays
```

Julia 1.13 or later. Every dependency is in the General registry.
VisualRadiometryToolkitCore defines the types that are saved and loaded;
VisualGeometryToolkitIO defines the two verbs, `load` and `save`.

## Example

The example saves a radial vignetting field and loads it back. `load` and
`save` are public in VisualGeometryToolkitIO but not exported, so they are
called through a module alias.

```julia
import VisualGeometryToolkitIO as VgtkIO
using VisualRadiometryToolkitCore, VisualRadiometryToolkitIO
using StaticArrays: SVector

path = joinpath(mktempdir(), "vignetting.json")
v = RadialVignetting(7, SVector(320.25, 241.75), 401.25)   # a radial profile of 7 control points: centre and radius in pixels
VgtkIO.save(path, v)
VgtkIO.load(AbstractVignetting, path) == v                 # true
VgtkIO.validate(path) == "vignetting"                      # true
```

## Documentation

- [The kinds](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/dev/guide/kinds/):
  the three file kinds, what each holds, earlier versions, and how another
  package's record embeds one of these values.
- [API Reference](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/dev/api/).

The [portal](https://visualradiometrytoolkit.github.io) links the packages of
the Visual Radiometry Toolkit.

## Citing

If you use the package, please cite the paper whose camera model the toolkit
carries:

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

MIT. See [LICENSE](LICENSE).

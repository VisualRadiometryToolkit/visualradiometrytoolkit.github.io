# VisualRadiometryToolkitCore.jl

[![CI](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/)

The core of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the types of a radiometric camera, a camera of the
[Visual Geometry Toolkit](https://visualgeometrytoolkit.github.io) together
with the parts that decide how much light a pixel collects (vignetting,
aperture, focus, sensor response). Each part is an abstract type whose default
is absent and compiles away.

**Under construction.** The package is a skeleton at the placeholder version
0.0.1 and is not in a registry. It holds the first part born here,
`NoVignetting`; the plan is in the
[Design page](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/guide/design/)
and in [`docs/design/inventory.md`](../docs/design/inventory.md).

## Installation

```julia-repl
pkg> add https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io:VisualRadiometryToolkitCore
```

Julia 1.13 or later. Every dependency is in the General registry.

## Example

```julia
using VisualGeometryToolkitCore, VisualRadiometryToolkitCore
using StaticArrays: SVector

v = NoVignetting()                    # the absent vignetting: V ≡ 1
v isa AbstractVignetting              # true: accepted wherever a vignetting is
v(SVector(1200.0, 800.0)) * 0.25      # 0.25: the factor is compiled away
parameter_names(v)                    # (): nothing to calibrate, no Jacobian columns
```

## License

MIT. See [LICENSE](LICENSE).

# VisualRadiometryToolkitCore.jl

The core of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the types of a radiometric camera. A radiometric camera is a camera of the
[Visual Geometry Toolkit](https://visualgeometrytoolkit.github.io) together
with the parts that decide how much light a pixel collects: its vignetting,
its aperture, its focus, its sensor's response.

Radiometry lifts geometry. This package depends on
[VisualGeometryToolkitCore](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/)
and follows its conventions (naming, signatures, frames, units, Jacobians),
which are stated once, [there](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/dev/guide/conventions/);
no package of the Visual Geometry Toolkit depends on this one.

!!! warning "Under construction"
    The package is a skeleton at the placeholder version 0.0.1 and is not in a
    registry. It holds the first part born here, [`NoVignetting`](@ref). The
    [Design](@ref) page states what is planned.

## Installation

```julia-repl
pkg> add https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io:VisualRadiometryToolkitCore
```

Julia 1.13 or later. Every dependency is in the General registry.

## Example

A camera that is given no vignetting attenuates nothing, and the absent
vignetting costs nothing: it has no parameters, and a kernel that multiplies by
its value is compiled to one that does not multiply.

```jldoctest
julia> using VisualGeometryToolkitCore, VisualRadiometryToolkitCore

julia> using StaticArrays: SVector

julia> v = NoVignetting();

julia> v isa AbstractVignetting
true

julia> v(SVector(1200.0, 800.0)) * 0.25
0.25

julia> parameter_names(v)
()
```

## Citing

If you use the toolkit, please cite the paper whose camera model it carries:

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

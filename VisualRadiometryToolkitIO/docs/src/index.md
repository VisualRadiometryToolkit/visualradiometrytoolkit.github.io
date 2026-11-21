# VisualRadiometryToolkitIO.jl

The file formats of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the vignetting fields, environment lights and measured radial profiles of
[VisualRadiometryToolkitCore](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/)
saved and loaded as self-describing JSON files, in the envelope and under the
schema rules of
[VisualGeometryToolkitIO](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitIO/)
(one envelope that declares units and conventions; every earlier schema
version a published file holds still loads).

## What it provides

- three file kinds, `vgio/vignetting`, `vgio/environment_light` and
  `vgio/radial_profile`, read and written with VisualGeometryToolkitIO's
  `load`, `save` and `validate` ([The kinds](@ref));
- the earlier versions of those kinds, read on load and rewritten once by
  `VisualGeometryToolkitIO.vgio_migrate`;
- the tables of the three bodies, for a record of another package that embeds
  a vignetting, a light or a radial profile
  ([Embedding a body in another record](@ref));
- a published JSON Schema of every kind ([JSON Schemas](@ref)).

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

## JSON Schemas

The JSON Schema (draft 2020-12) of each kind is generated from the table its
reader checks and published with this manual:

| Schema (its `$id` is this path below `https://visualradiometrytoolkit.github.io/schemas/`) |
|---|
| [`vgio/environment_light/v2.0.json`](schemas/vgio/environment_light/v2.0.json) |
| [`vgio/radial_profile/v1.0.json`](schemas/vgio/radial_profile/v1.0.json) |
| [`vgio/vignetting/v2.0.json`](schemas/vgio/vignetting/v2.0.json) |

[`json_schemas`](@ref VisualRadiometryToolkitIO.json_schemas) returns them; a
test holds the published files to the generator's output.

## Documentation

- **Explanation and how-to**: [The kinds](@ref), what each kind holds, where
  the kinds came from, and how a record of another package embeds a body.
- **Reference**: the [API Reference](@ref).

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

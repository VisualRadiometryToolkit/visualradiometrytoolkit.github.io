# VisualRadiometryToolkitIO.jl

The file formats of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the radiometric types of
[VisualRadiometryToolkitCore](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/)
saved and loaded as self-describing files, in the envelope and under the
schema rules of
[VisualGeometryToolkitIO](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitIO/)
(one envelope that declares units and conventions; every earlier schema
version a published file holds still loads).

!!! warning "Under construction"
    The package is at the placeholder version 0.0.1 and is not in a registry.

## The kinds

Each kind is the serialization of one VisualRadiometryToolkitCore type. The
two verbs are VisualGeometryToolkitIO's, `load(T, path)` and `save(path,
value)`; this package adds the methods for its types, so a reader reaches
every kind of the stack through the same two calls.

| Kind | Value | Read | Written |
|---|---|---|---|
| `vgio/vignetting/v2.0` | an `AbstractVignetting`: a `TensorProductVignetting` (its knots stated), a `RadialVignetting` (its `chart` always stated) or a `LogVignetting`, positions in any registered pixel frame (`units.pixel`); rebuilt bit for bit | `load(AbstractVignetting, path)` | `save(path, v)` |
| `vgio/environment_light/v2.0` | an `EnvironmentLight` of a `SphericalHarmonicMap`: centre and radius in `units.length` (a plain light refused), coefficients per channel in `units.radiance`, the degree `max_degree` and the basis convention stated (`real_orthonormal_no_condon_shortley`) | `load(EnvironmentLight, path)` | `save(path, light; length_unit = mm)` |
| `vgio/radial_profile/v1.0` | a `BinnedRadialProfile`: a measured profile binned by its chart's coordinate (a flat field by field angle), its chart's centre and radius in `units.pixel`, its edges in `units.angle` | `load(BinnedRadialProfile, path)` | `save(path, p)` |

```julia
import VisualGeometryToolkitIO as VgtkIO
using VisualRadiometryToolkitCore, VisualRadiometryToolkitIO
using StaticArrays: SVector

v = RadialVignetting(7, SVector(320.25, 241.75), 401.25)      # a radial profile of 7 control points
VgtkIO.save("vignetting.json", v)
VgtkIO.load(AbstractVignetting, "vignetting.json") == v      # true
VgtkIO.validate("vignetting.json")                           # "vignetting"
```

## Where the kinds came from

The three kinds were VisualGeometryToolkitIO's up to its 0.10 and moved here
with the types they hold. Their schema names did not change, so a file written
before the move loads here as it is. A `vgio/vignetting/v1` or
`vgio/environment_light/v1` file (VisualGeometryToolkitIO 0.9's) reads through
its version step, and `VisualGeometryToolkitIO.vgio_migrate(path)` rewrites
one once. Without this package loaded, VisualGeometryToolkitIO refuses a file
of these kinds by name and names this package.

## Embedding a body in another record

Each body is a value on VisualGeometryToolkitIO's `VgioStyle`: a record of
another package that holds a vignetting, a light or a radial profile writes it
with `JSON.lower(style, value)` (or leaves the value in the record for the
style to lower) and reads it with `JSON.lift(style, AbstractVignetting,
record)`, `JSON.lift(style, EnvironmentLight, record)` or `JSON.lift(style,
BinnedRadialProfile, record)`. A kind that states its table
(`VisualGeometryToolkitIO.KindSpec`) names the body's table:
[`VIGNETTING_BODY`](@ref VisualRadiometryToolkitIO.VIGNETTING_BODY),
[`ENVIRONMENT_LIGHT_BODY`](@ref VisualRadiometryToolkitIO.ENVIRONMENT_LIGHT_BODY),
[`RADIAL_PROFILE_BODY`](@ref VisualRadiometryToolkitIO.RADIAL_PROFILE_BODY).

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

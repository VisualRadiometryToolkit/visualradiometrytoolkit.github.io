"""
    VisualRadiometryToolkitIO

The file formats of the Visual Radiometry Toolkit: the radiometric types of
VisualRadiometryToolkitCore saved and loaded as self-describing files, in the
envelope and under the schema rules of VisualGeometryToolkitIO.

Three kinds, each the serialization of one VisualRadiometryToolkitCore type,
read and written by VisualGeometryToolkitIO's two verbs (this package adds the
methods; `import VisualGeometryToolkitIO as VgtkIO`):

| kind | value | read | written |
|---|---|---|---|
| `vgio/vignetting/v2.0` | an `AbstractVignetting` (tensor-product, radial or log field) | `VgtkIO.load(AbstractVignetting, path)` | `VgtkIO.save(path, v)` |
| `vgio/environment_light/v2.0` | an `EnvironmentLight` of a `SphericalHarmonicMap` | `VgtkIO.load(EnvironmentLight, path)` | `VgtkIO.save(path, light)` |
| `vgio/radial_profile/v1.0` | a `BinnedRadialProfile` | `VgtkIO.load(BinnedRadialProfile, path)` | `VgtkIO.save(path, p)` |

The kinds were VisualGeometryToolkitIO's up to its 0.10 and keep their schema
names, so every file written before the move loads here, bit for bit; a
`vgio/vignetting/v1` or `vgio/environment_light/v1` file reads through its
version step. Each body is a value on VisualGeometryToolkitIO's `VgioStyle`
(`JSON.lower(style, value)`, `JSON.lift(style, T, record)`), so another
package's record nests it, and each kind's table is public for a record that
embeds the body ([`VIGNETTING_BODY`](@ref), [`ENVIRONMENT_LIGHT_BODY`](@ref),
[`RADIAL_PROFILE_BODY`](@ref)).
"""
module VisualRadiometryToolkitIO

import VisualGeometryToolkitCore as VgtkCore
import VisualGeometryToolkitIO as VgtkIO

using JSON: JSON
using StaticArrays: SVector
using FlexUnits: Units
using VisualGeometryToolkitCore: PixelFrame, BaseQuantity, tag_of, has_units, mm
using VisualGeometryToolkitIO: VgioStyle, Record, KindSpec
using VisualRadiometryToolkitCore: AbstractVignetting, TensorProductVignetting, RadialVignetting, LogVignetting, log_spline,
    VIGNETTING_TAGS, RADIAL_CHARTS, radial_chart, field_radius, knot_vectors, spline_degree, control_points, with_control_points,
    EnvironmentLight, SphericalHarmonicMap, coefficients, max_degree, BinnedRadialProfile

# -----------------------------------------------------------------------------
# What every kind here shares
# -----------------------------------------------------------------------------

# The pixel frame VisualRadiometryToolkitCore's values hold their positions in (a field's knots and centre, a profile's
# centre): COLMAP pixels. A file in another frame moves them by the frames' offset on the way in and out.
const _VALUE_PIXEL_FRAME = PixelFrame{:colmap}
_to_file(s::VgioStyle) = VgtkIO.pixel_frame_offset(_VALUE_PIXEL_FRAME, VgtkIO.pixel_frame(s))
_from_file(s::VgioStyle) = VgtkIO.pixel_frame_offset(VgtkIO.pixel_frame(s), _VALUE_PIXEL_FRAME)

# A matrix stored as its rows (a tensor surface's control points, a light's coefficients per channel, a profile's values
# per channel), read back as a Matrix{Float64}…
_rows_matrix(rows) = reduce(vcat, (permutedims(Float64[Float64(x::Real) for x in r]) for r in rows))
# …and written: its rows, each a Vector{Float64}.
_matrix_rows(A::AbstractMatrix) = [Float64[A[i, j] for j in axes(A, 2)] for i in axes(A, 1)]

# Where the published JSON Schemas of these kinds live (docs/src/schemas, at the path of each schema string).
const _SCHEMA_SITE = "https://visualradiometrytoolkit.github.io/schemas/"

# A kind whose file is the envelope and ONE key, the value's body (the vignetting's `vignetting`, the radial profile's
# `profile`): written on the canonical style (COLMAP pixels, no length), and read back on the style the file declares.
function _save_keyed(path::AbstractString, kind::KindSpec, key::Symbol, value, provenance::NamedTuple)
    s = VgioStyle()
    VgtkIO.write_kind(path, kind, NamedTuple{(key,)}((JSON.lower(s, value),)); style = s, provenance)
    return nothing
end
function _load_keyed(::Type{T}, path::AbstractString, kind::KindSpec, key::Symbol) where {T}
    d = VgtkIO.read_kind(path, kind)
    return JSON.lift(VgioStyle(d), T, d[key]::Record)
end
# The version step of a record written before VisualGeometryToolkitIO 0.10: its envelope as `schema`'s, and its `key`
# carried over by `carry`.
function _migrated(old::AbstractDict, schema::AbstractString, key::AbstractString, carry)
    t = VgtkIO.migrate_envelope(old, schema)
    t[key] = carry(t[key])
    return t
end

include("vignetting_schema.jl")         # vgio/vignetting/v2.0 ↔ an AbstractVignetting; the v1 step
include("environment_light_schema.jl")  # vgio/environment_light/v2.0 ↔ an EnvironmentLight; the v1 step
include("radial_profile_schema.jl")     # vgio/radial_profile/v1.0 ↔ a BinnedRadialProfile

"""
    json_schemas() -> Vector{Pair{String, JSON.Object}}

The JSON Schemas (draft 2020-12) of this package's kinds, each generated from
the kind's table (`VisualGeometryToolkitIO.json_schema`): `path => schema`,
`path` the schema string followed by `.json` (`vgio/vignetting/v2.0.json`), the
schema's `\$id` that path below `https://visualradiometrytoolkit.github.io/schemas/`.
`JSON.json(schema; pretty = 4)` is the published file (docs/src/schemas).
"""
json_schemas() = [schema * ".json" => VgtkIO.json_schema(kind; id_base = _SCHEMA_SITE)
                  for (schema, kind) in (_ENVIRONMENT_LIGHT_SCHEMA => ENVIRONMENT_LIGHT_KIND, _RADIAL_PROFILE_SCHEMA => RADIAL_PROFILE_KIND,
                                         _VIGNETTING_SCHEMA => VIGNETTING_KIND)]

# A listed file of each kind, for `VisualGeometryToolkitIO.validate` and a calibration manifest: the owner of a `vgio`
# kind that moved is keyed by the kind (VisualGeometryToolkitIO's `validate_record`).
for (key, kind) in (Symbol("vgio/vignetting") => :VIGNETTING_KIND, Symbol("vgio/environment_light") => :ENVIRONMENT_LIGHT_KIND,
                    Symbol("vgio/radial_profile") => :RADIAL_PROFILE_KIND)
    @eval VgtkIO.validate_record(::Val{$(QuoteNode(key))}, path::AbstractString, schema::AbstractString) = (VgtkIO.read_kind(path, $kind); nothing)
end

public VIGNETTING_KIND, ENVIRONMENT_LIGHT_KIND, RADIAL_PROFILE_KIND   # the kinds: each one's schema and table (a VisualGeometryToolkitIO KindSpec)
public VIGNETTING_BODY, ENVIRONMENT_LIGHT_BODY, RADIAL_PROFILE_BODY   # the tables of the bodies, for a record of another package that embeds one
public migrate_vignetting_body   # a vgio/vignetting/v1 body as the v2.0 one: the part of another package's version step that is this kind's
public json_schemas              # the published JSON Schemas of the kinds

end # module

# =============================================================================
# vgio/environment_light/v2.0 ↔ VisualRadiometryToolkitCore's EnvironmentLight
# =============================================================================
#
# {"schema": "vgio/environment_light/v2.0", <envelope>, "center": [x, y, z], "radius": r,
#  "map": {"type": "spherical_harmonics", "basis": "real_orthonormal_no_condon_shortley", "max_degree": L,
#          "coefficients": [[a₁, …, a_J], …]}}                              (one row per channel, J = (L+1)²)
#      An EnvironmentLight of a SphericalHarmonicMap: the centre and radius lengths in `units.length` (metres as
#      quantities in memory; a plain light is refused — `with_unit(light, m)`), the coefficients in `units.radiance`
#      ("relative": known up to scale); the basis convention stated, so a file is never read in another one (`sh_basis`:
#      real, orthonormal, no Condon–Shortley phase, j = l² + l + m + 1). `max_degree` is the type's name
#      (`max_degree(light)`).
#
# The body (centre, radius in the style's length unit, map) is a value on VisualGeometryToolkitIO's style:
# `JSON.lower(style, light)`, `JSON.lift(style, EnvironmentLight, record)`; its table is `ENVIRONMENT_LIGHT_BODY`.
# The lengths cross by VisualGeometryToolkitIO's decimal-exact length rule — a decimal file number reads back exactly.
#
# The kind was VisualGeometryToolkitIO's up to its 0.10 (radiometry_schema.jl) and keeps its schema name.

const _ENVIRONMENT_LIGHT_SCHEMA = "vgio/environment_light/v2.0"
const _SH_BASIS = "real_orthonormal_no_condon_shortley"

const _ENVIRONMENT_LIGHT_KEYS = [
    :center => VgtkIO.array_spec(VgtkIO.real_spec(); length = 3), :radius => VgtkIO.real_spec(),
    :map => VgtkIO.checked_spec(
        VgtkIO.object_spec(:type => VgtkIO.token_spec("spherical_harmonics"), :basis => VgtkIO.token_spec(_SH_BASIS),
                           :max_degree => VgtkIO.integer_spec(), :coefficients => VgtkIO.array_spec(VgtkIO.array_spec(VgtkIO.real_spec()))),
        m -> all(r -> length(r) == (m[:max_degree] + 1)^2, m[:coefficients]) ? nothing :
            "every channel has (max_degree + 1)² = $((m[:max_degree] + 1)^2) coefficients";
        rule = "every channel (a row of `coefficients`) has (max_degree + 1)² coefficients",
    ),
]

"""
    ENVIRONMENT_LIGHT_BODY

The table of the environment-light body (a `VisualGeometryToolkitIO` spec):
`{"center": [x, y, z], "radius": r, "map": {"type": "spherical_harmonics",
"basis": "real_orthonormal_no_condon_shortley", "max_degree": L,
"coefficients": [[…], …]}}`, the lengths in the record's `units.length`, every
channel holding `(L + 1)²` coefficients. They are the keys of a
`vgio/environment_light` file ([`ENVIRONMENT_LIGHT_KIND`](@ref)), and the table
a kind of another package states for a light it embeds, written with
`JSON.lower(style, light)` and read with `JSON.lift(style, EnvironmentLight,
record)`.
"""
const ENVIRONMENT_LIGHT_BODY = VgtkIO.object_spec(_ENVIRONMENT_LIGHT_KEYS[1], _ENVIRONMENT_LIGHT_KEYS[2], _ENVIRONMENT_LIGHT_KEYS[3])

"""
    ENVIRONMENT_LIGHT_KIND

The `vgio/environment_light/v2.0` kind (a `VisualGeometryToolkitIO.KindSpec`):
the envelope, then the keys of the [`ENVIRONMENT_LIGHT_BODY`](@ref).
`vgio/environment_light/v1` reads through its version step.
"""
const ENVIRONMENT_LIGHT_KIND = KindSpec(_ENVIRONMENT_LIGHT_SCHEMA, _ENVIRONMENT_LIGHT_KEYS; package = "VisualRadiometryToolkitIO")

"""
    VisualGeometryToolkitIO.save(path, light::EnvironmentLight; length_unit = mm, provenance = (;))

Write an `EnvironmentLight` of a `SphericalHarmonicMap` as a
`vgio/environment_light/v2.0` file: its centre and radius in `length_unit`
(decimal-exact; a plain light — no units — is an `ArgumentError` naming
`with_unit(light, m)`), and its coefficients per channel with the basis
convention stated, in `units.radiance` ("relative").
`VisualGeometryToolkitIO.load(EnvironmentLight, path)` gives the same light back.
"""
function VgtkIO.save(path::AbstractString, light::EnvironmentLight{<:SphericalHarmonicMap}; length_unit::Units = mm, provenance::NamedTuple = (;))
    s = VgioStyle(; length_unit)
    VgtkIO.write_kind(path, ENVIRONMENT_LIGHT_KIND, JSON.lower(s, light); style = s, provenance)
    return nothing
end

# The light's body (no `schema`, no `length_unit`: the enclosing record's): its centre and radius in the style's
# length unit, decimal-exact; a plain light is refused, naming `with_unit(light, m)`.
function JSON.lower(s::VgioStyle, light::EnvironmentLight{<:SphericalHarmonicMap})
    has_units(light) || throw(ArgumentError(
        "save: the light's centre and radius are lengths; give them units, `with_unit(light, m)` (metres in memory)"))
    a = coefficients(light)
    return (
        center = [VgtkIO.write_length(c, s.length_unit) for c in VgtkCore.center(light)],
        radius = VgtkIO.write_length(VgtkCore.radius(light), s.length_unit),
        map = (type = "spherical_harmonics", basis = _SH_BASIS, max_degree = max_degree(light),
               coefficients = _matrix_rows(a)),
    )
end
function JSON.lift(s::VgioStyle{<:Units}, ::Type{EnvironmentLight}, d::Record)
    a = _rows_matrix(d.map.coefficients::Vector{Any})
    c = d.center::Vector{Any}
    center = SVector{3, BaseQuantity}(ntuple(i -> VgtkIO.read_length(c[i]::Real, s.length_unit), Val(3)))
    return EnvironmentLight(SphericalHarmonicMap(a, Int(d.map.max_degree)), center, VgtkIO.read_length(d.radius::Real, s.length_unit))
end

"""
    VisualGeometryToolkitIO.load(EnvironmentLight, path) -> EnvironmentLight

Read a `vgio/environment_light/v2.0` file: the light `save` wrote, its centre
and radius lengths in metres. A v1 file is read through its version step.
"""
function VgtkIO.load(::Type{EnvironmentLight}, path::AbstractString)
    d = VgtkIO.read_kind(path, ENVIRONMENT_LIGHT_KIND)
    return JSON.lift(VgioStyle(d), EnvironmentLight, d::Record)
end

VgtkIO.validate_record(::Val{Symbol("vgio/environment_light")}, path::AbstractString, schema::AbstractString) =
    (VgtkIO.read_kind(path, ENVIRONMENT_LIGHT_KIND); nothing)

# --- vgio/environment_light/v1 → v2.0 ---------------------------------------------
# The envelope (its coefficients' radiance "relative", as v1 left them in the caller's units); `l_max` → `max_degree`,
# the type's name.
function VgtkIO.migrate_schema(::Val{Symbol("vgio/environment_light/v1")}, old::AbstractDict)
    t = VgtkIO.migrate_envelope(old, _ENVIRONMENT_LIGHT_SCHEMA)
    t["map"] = Dict{String, Any}((k == "l_max" ? "max_degree" : String(k)) => v for (k, v) in t["map"])
    return t
end
VgtkIO.migrate_schema(::Val{Symbol("vgio/environment_light/v1")}, src::AbstractString, dst::AbstractString) =
    VgtkIO.migrate_file(EnvironmentLight, ENVIRONMENT_LIGHT_KIND, src, dst; what = "the environment light")

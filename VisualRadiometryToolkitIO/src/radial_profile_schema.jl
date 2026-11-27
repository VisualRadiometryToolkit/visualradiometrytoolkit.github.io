# =============================================================================
# vgio/radial_profile/v1.0 ↔ VisualRadiometryToolkitCore's `BinnedRadialProfile` — a measured radial profile, binned (a
# flat field by field angle)
# =============================================================================
#
# {"schema": "vgio/radial_profile/v1.0", <envelope>,
#  "profile": {"type": "binned_radial_profile",
#              "chart": {"type": "equisolid", "center": [cx, cy], "radius": r, "focal_length": f},   (pixels: units.pixel)
#              "edges": [θ0, θ1, …, θB],          (the chart's coordinate: equisolid in units.angle, rad; B+1 increasing)
#              "values": [[v1, …, vB], …],         (one row per channel; unitless)
#              "counts": [n1, …, nB]}}             (pixels per bin; bin b, 1-based, is [edges[b], edges[b+1]))
#
# A MEASURED profile, binned rather than fitted: the vignetting bodies are fitted fields (splines), so this is its own
# body; its CHART is the one radial-chart vocabulary (a tag of `RADIAL_CHART_TAGS`: linear, projective, equisolid), the equisolid
# chart alone stating its focal length. The profile's centre and radius are COLMAP pixels in the value and written in
# the file's pixel frame (moved by the style, as the vignetting body's positions). The body is embeddable
# (`JSON.lower(::VgioStyle, ::BinnedRadialProfile)`, `JSON.lift(style, BinnedRadialProfile, body)`; its table
# `RADIAL_PROFILE_BODY`).
#
# The kind was VisualGeometryToolkitIO's in its 0.10 and keeps its schema name.

const _RADIAL_PROFILE_SCHEMA = "vgio/radial_profile/v1.0"

const _PROFILE_CHART = VgtkIO.if_key_spec(:focal_length,
    VgtkIO.object_spec(:type => VgtkIO.named_spec(==("equisolid"), "the equisolid chart (the one that states a focal length)"),
                       :center => VgtkIO.body_spec(PixelFrame), :radius => VgtkIO.real_spec(), :focal_length => VgtkIO.real_spec()),
    VgtkIO.object_spec(:type => _RADIAL_CHART, :center => VgtkIO.body_spec(PixelFrame), :radius => VgtkIO.real_spec()))
function _radial_profile_check(x)
    B = length(x[:edges]) - 1
    B >= 1 || return "edges: at least two (B + 1 edges for B bins)"
    all(i -> x[:edges][i] < x[:edges][i + 1], 1:B) || return "edges: strictly increasing"
    isempty(x[:values]) && return "values: one row per channel, at least one"
    all(r -> length(r) == B, x[:values]) || return "values: every channel has one value per bin ($(B))"
    length(x[:counts]) == B || return "counts: one pixel count per bin ($(B))"
    all(>=(0), x[:counts]) || return "counts: each ≥ 0"
    (x[:chart][:type] == "equisolid") == haskey(x[:chart], :focal_length) || return "chart: the equisolid chart states its focal length, and only it"
    return nothing
end

"""
    RADIAL_PROFILE_BODY

The table of the binned radial-profile body (a `VisualGeometryToolkitIO`
spec): `{"type": "binned_radial_profile", "chart": {"type", "center",
"radius"[, "focal_length"]}, "edges", "values", "counts"}` — `B + 1` strictly
increasing edges, one row of `B` values per channel, `B` counts each ≥ 0, the
equisolid chart alone stating its focal length. It is the `profile` key of a
`vgio/radial_profile` file ([`RADIAL_PROFILE_KIND`](@ref)), and the table a
kind of another package states for a profile it embeds, written with
`JSON.lower(style, p)` and read with `JSON.lift(style, BinnedRadialProfile,
record)`.
"""
const RADIAL_PROFILE_BODY = VgtkIO.checked_spec(
    VgtkIO.object_spec(
        :type => VgtkIO.token_spec("binned_radial_profile"), :chart => _PROFILE_CHART, :edges => VgtkIO.array_spec(VgtkIO.real_spec()),
        :values => VgtkIO.array_spec(VgtkIO.array_spec(VgtkIO.real_spec())), :counts => VgtkIO.array_spec(VgtkIO.integer_spec())),
    _radial_profile_check;
    rule = "B + 1 strictly increasing edges (B ≥ 1); `values` one row per channel (at least one), B values each; " *
           "`counts` B counts, each ≥ 0; the equisolid chart states its focal length, and only it",
    schema = [Dict("properties" => Dict("edges" => Dict("minItems" => 2), "values" => Dict("minItems" => 1),
                                        "counts" => Dict("items" => Dict("minimum" => 0)),
                                        "chart" => Dict("if" => Dict("properties" => Dict("type" => Dict("const" => "equisolid"))),
                                                        "then" => Dict("required" => ["focal_length"]))))])

"""
    RADIAL_PROFILE_KIND

The `vgio/radial_profile/v1.0` kind (a `VisualGeometryToolkitIO.KindSpec`): the
envelope and one key, `profile`, the [`RADIAL_PROFILE_BODY`](@ref).
"""
const RADIAL_PROFILE_KIND = KindSpec(_RADIAL_PROFILE_SCHEMA, [:profile => RADIAL_PROFILE_BODY]; package = "VisualRadiometryToolkitIO")

function JSON.lower(s::VgioStyle, p::BinnedRadialProfile)
    c = VgtkCore.center(p) + _to_file(s)
    chart = merge((type = tag_of(RADIAL_CHART_TAGS, radial_chart(p)), center = Float64[c[1], c[2]], radius = field_radius(p)),
                  p.focal_length === nothing ? (;) : (focal_length = p.focal_length,))
    return (type = "binned_radial_profile", chart = chart, edges = p.edges, values = VgtkIO.matrix_rows(p.values), counts = p.counts)
end
function JSON.lift(s::VgioStyle, ::Type{BinnedRadialProfile}, b::Record)
    ch = b.chart
    c = SVector(Float64(ch.center[1]::Real), Float64(ch.center[2]::Real)) + _from_file(s)
    return BinnedRadialProfile(RADIAL_CHART_TAGS[ch.type::String](), c, Float64(ch.radius::Real), Float64[Float64(e::Real) for e in b.edges],
                               VgtkIO.rows_matrix(b.values::Vector{Any}), Int[Int(n::Integer) for n in b.counts];
                               focal_length = haskey(ch, :focal_length) ? Float64(ch.focal_length::Real) : nothing)
end

const _RADIAL_PROFILE_SAVE_DOC = """
    VisualGeometryToolkitIO.save(path, value::BinnedRadialProfile; provenance = (;))

Write a `BinnedRadialProfile` — a measured radial profile (a flat field binned
by field angle) — as a `vgio/radial_profile/v1.0` file: its chart (a tag of
`RADIAL_CHART_TAGS`: its centre and image-circle radius in pixels, the equisolid
chart's focal length), the `B + 1` bin edges in the chart's coordinate (radians
for equisolid), the `channels × B` values (one row per channel) and the `B`
pixel counts.
"""
const _RADIAL_PROFILE_LOAD_DOC = """
    VisualGeometryToolkitIO.load(BinnedRadialProfile, path) -> BinnedRadialProfile

Read a `vgio/radial_profile/v1.0` file (`save`'s): the profile exactly as
written, its centre in COLMAP pixels (a file in another pixel frame moved into
them).
"""

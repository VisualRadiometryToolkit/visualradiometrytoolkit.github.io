# =============================================================================
# vgio/vignetting/v2.0 ↔ VisualRadiometryToolkitCore's vignetting fields
# =============================================================================
#
# The file opens with VisualGeometryToolkitIO's envelope (`units`, `conventions`, `generator`).
#
# {"schema": "vgio/vignetting/v2.0", <envelope>,
#  "vignetting": {"type": "tensor_product", "degree": [p, q], "knots_x": […], "knots_y": […],
#                 "control_points": [[P₁₁, …, P₁ny], …, [Pnx1, …]]}            (row i: x index i)
#              | {"type": "radial", "degree": p, "center": [cx, cy], "radius": r, "chart": "linear" | "projective",
#                 "control_points": [P₁, …]}
#              | {"type": "log", "spline": {a tensor_product or radial body}}}
#      TensorProductVignetting, RadialVignetting, LogVignetting: positions in pixels of the file's `units.pixel` (any
#      registered pixel frame; the fields hold COLMAP pixels, so a file in another frame moves them by its offset on
#      the way in), V unitless; a tensor surface's knots are stated (rebuilt exactly); a radial profile's are its
#      count's, degree's and chart's (`RADIAL_CHARTS`, always stated: a declaration has no default).
#
# The body is a value on VisualGeometryToolkitIO's style, so another kind's record can nest it:
# `JSON.lower(style, v)` and `JSON.lift(style, AbstractVignetting, record)`; its table is `VIGNETTING_BODY`. The kind's
# save/load go through the same methods. Every number crosses as it is.
#
# The kind was VisualGeometryToolkitIO's up to its 0.10 (radiometry_schema.jl) and keeps its schema name: a file
# written there loads here, bit for bit.

const _VIGNETTING_SCHEMA = "vgio/vignetting/v2.0"

# A body is told by its `type`, the field's tag in `VIGNETTING_TAGS`; a log field holds a spline body.
_vignetting_type(T::Type{<:AbstractVignetting}) = VgtkIO.token_spec(tag_of(VIGNETTING_TAGS, T))
_vignetting_body(T::Type{<:TensorProductVignetting}, self) = VgtkIO.object_spec(
    :type => _vignetting_type(T), :degree => VgtkIO.array_spec(VgtkIO.integer_spec(; positive = true); length = 2),
    :knots_x => VgtkIO.array_spec(VgtkIO.real_spec()), :knots_y => VgtkIO.array_spec(VgtkIO.real_spec()),
    :control_points => VgtkIO.array_spec(VgtkIO.array_spec(VgtkIO.real_spec())))
_vignetting_body(T::Type{<:RadialVignetting}, self) = VgtkIO.object_spec(
    :type => _vignetting_type(T), :degree => VgtkIO.integer_spec(; positive = true),
    :center => VgtkIO.array_spec(VgtkIO.real_spec(); length = 2), :radius => VgtkIO.real_spec(),
    :chart => VgtkIO.named_spec(in(String.(RADIAL_CHARTS)), "a radial chart ($(join(String.(RADIAL_CHARTS), ", ")))"),
    :control_points => VgtkIO.array_spec(VgtkIO.real_spec()))
_vignetting_body(T::Type{<:LogVignetting}, self) = VgtkIO.object_spec(:type => _vignetting_type(T), :spline => self)
_vignetting_tags() = join(keys(VIGNETTING_TAGS), ", ")
# A `type` no field has: the registry's own message (an unknown tag lists the known ones, a retired one names its successor).
function _unknown_vignetting(tag)
    try
        VIGNETTING_TAGS[tag]
    catch err
        err isa ArgumentError || rethrow()
        return err.msg
    end
    return "$(repr(tag)) is not a vignetting type ($(_vignetting_tags()))"
end

"""
    VIGNETTING_BODY

The table of the vignetting body (a `VisualGeometryToolkitIO` spec): an object
told by its `type`, a tag of VisualRadiometryToolkitCore's `VIGNETTING_TAGS` —
`{"type": "tensor_product", "degree": [p, q], "knots_x", "knots_y",
"control_points"}`, `{"type": "radial", "degree", "center", "radius", "chart",
"control_points"}` or `{"type": "log", "spline": <a body>}`. It is the
`vignetting` key of a `vgio/vignetting` file ([`VIGNETTING_KIND`](@ref)), and
the table a kind of another package states for a vignetting it embeds
(PanoramaStitching's panorama), whose value it writes with
`JSON.lower(style, v)` and reads with `JSON.lift(style, AbstractVignetting,
record)`.
"""
const VIGNETTING_BODY = VgtkIO.tagged_spec("a vignetting"; def = "vignetting", unknown = _unknown_vignetting) do self
    [String(t) => _vignetting_body(VIGNETTING_TAGS[t], self) for t in keys(VIGNETTING_TAGS)]
end

"""
    VIGNETTING_KIND

The `vgio/vignetting/v2.0` kind (a `VisualGeometryToolkitIO.KindSpec`): the
envelope and one key, `vignetting`, the [`VIGNETTING_BODY`](@ref).
`VisualGeometryToolkitIO.json_schema(VIGNETTING_KIND)` is its JSON Schema and
`VisualGeometryToolkitIO.schema_versions(VIGNETTING_KIND)` the versions read
(`vgio/vignetting/v1` through its version step).
"""
const VIGNETTING_KIND = KindSpec(_VIGNETTING_SCHEMA, [:vignetting => VIGNETTING_BODY]; package = "VisualRadiometryToolkitIO")

# The `vignetting` body, on the style: positions in the style's pixel frame (the fields hold COLMAP pixels), no length.
function JSON.lower(s::VgioStyle, v::TensorProductVignetting)
    c = _to_file(s)
    return (
        type = tag_of(VIGNETTING_TAGS, v), degree = collect(spline_degree(v)),
        knots_x = Float64.(collect(knot_vectors(v)[1])) .+ c[1], knots_y = Float64.(collect(knot_vectors(v)[2])) .+ c[2],
        control_points = _matrix_rows(control_points(v)),
    )
end
# A radial profile states its chart always (a declaration has no default).
function JSON.lower(s::VgioStyle, v::RadialVignetting)
    c = _to_file(s)
    return (type = tag_of(VIGNETTING_TAGS, v), degree = only(spline_degree(v)), center = Float64.(collect(VgtkCore.center(v)) .+ c),
            radius = Float64(field_radius(v)), chart = String(radial_chart(v)), control_points = Float64.(collect(vec(control_points(v)))))
end
JSON.lower(s::VgioStyle, v::LogVignetting) = (type = tag_of(VIGNETTING_TAGS, v), spline = JSON.lower(s, log_spline(v)))
JSON.lower(::VgioStyle, v::AbstractVignetting) = throw(ArgumentError("save: a $(typeof(v)) has no vgio/vignetting body ($(_vignetting_tags()))"))

JSON.lift(s::VgioStyle, ::Type{AbstractVignetting}, b::Record) = _lift_vignetting(s, VIGNETTING_TAGS[b.type::String], b)
_lift_vignetting(s::VgioStyle, ::Type{<:LogVignetting}, b::Record) = LogVignetting(JSON.lift(s, AbstractVignetting, b.spline::Record))
function _lift_vignetting(s::VgioStyle, ::Type{<:TensorProductVignetting}, b::Record)
    c = _from_file(s)
    P = _rows_matrix(b.control_points::Vector{Any})
    return TensorProductVignetting(Float64[Float64(x::Real) + c[1] for x in b.knots_x], Float64[Float64(x::Real) + c[2] for x in b.knots_y], P;
        degree = (Int(b.degree[1]), Int(b.degree[2])))
end
function _lift_vignetting(s::VgioStyle, ::Type{<:RadialVignetting}, b::Record)
    c = _from_file(s)
    P = Float64[Float64(x::Real) for x in b.control_points]
    chart = Symbol(b.chart::String)
    p = Int(b.degree)
    # the projective knots need more than 2p control points (VisualGeometryToolkitCore 0.10.11's rule, now this stack's
    # `projective_knots`: p − 1 knots beyond the rim at the pixel spacing); a record of fewer was written under the
    # earlier rule, which no reader rebuilds
    (chart === :projective && length(P) <= 2p) && throw(ArgumentError(
        "load: a vgio/vignetting radial profile on the projective chart has $(length(P)) control points of degree $p; its knots " *
            "(VisualGeometryToolkitCore 0.10.11's projective_knots) need at least $(2p + 1) (2p + 1). A record of fewer " *
            "was written under the knot rule before Core 0.10.11 (one span beyond the rim): refit the profile"))
    v = RadialVignetting(length(P), SVector(Float64(b.center[1]) + c[1], Float64(b.center[2]) + c[2]), Float64(b.radius); degree = p, chart)
    return with_control_points(v, P)
end

# The docstrings of the kind's `save` and `load` (methods of VisualGeometryToolkitIO's two verbs, defined with every
# kind's at the end of the module, from one definition).
const _VIGNETTING_SAVE_DOC = """
    VisualGeometryToolkitIO.save(path, value::AbstractVignetting; provenance = (;))

Write a vignetting field — a `TensorProductVignetting`, `RadialVignetting` or
`LogVignetting` — as a `vgio/vignetting/v2.0` file: its type, degree, knots
(a tensor surface's, stated) or centre, radius and chart (a radial profile's), and
control points, positions in COLMAP pixels (the file's `units.pixel`).
`VisualGeometryToolkitIO.load(AbstractVignetting, path)` gives the same field
back, bit for bit, for a radial profile on its chart's own knots (the record
holds no knots: a profile built from explicit knots reads back on its chart's rule).
A field with no body (`NoVignetting`) is an `ArgumentError`.
"""
const _VIGNETTING_LOAD_DOC = """
    VisualGeometryToolkitIO.load(AbstractVignetting, path) -> AbstractVignetting

Read a `vgio/vignetting/v2.0` file: the vignetting field `save` wrote, its
positions moved from the file's `units.pixel` into COLMAP pixels (the fields'
own). A v1 file (with or without its `chart`, which VisualGeometryToolkitIO 0.9
added inside v1) is read through its version step. A radial profile's knots are
its chart's rule at its count and degree (`projective_knots` on the projective
chart); a projective record of `n ≤ 2p` control points is refused
(`ArgumentError`), the knots needing at least `2p + 1`.
"""

# --- vgio/vignetting/v1 → v2.0 ---------------------------------------------------

"""
    migrate_vignetting_body(body::AbstractDict) -> AbstractDict

A `vgio/vignetting/v1` body (a parsed record, `String` keys) as the v2.0 body:
a radial profile states its chart — absent, the linear chart v1 read it in
(VisualGeometryToolkitIO 0.8's body); present (VisualGeometryToolkitIO 0.9
wrote a non-linear profile's `chart` inside v1), as it stands. A log field's
spline is a body too. The `vgio/vignetting/v1` version step runs it, and so
does the version step of another package's record that embeds a v1 body
(PanoramaStitching's `vgio/panorama/v1`).
"""
migrate_vignetting_body(b::AbstractDict) =
    b["type"] == "log" ? merge(b, Dict{String, Any}("spline" => migrate_vignetting_body(b["spline"]))) :
    (b["type"] == "radial" && !haskey(b, "chart")) ? merge(b, Dict{String, Any}("chart" => "linear")) : b

# The version step itself — the envelope (v1's `pixel_frame`, always colmap), then this body — and its file form are
# defined with the environment light's, at the end of the module.

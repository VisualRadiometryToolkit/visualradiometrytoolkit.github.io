# ---------------------------------------------------------------------------
# Focus surface Θ_f = {t̂_i}: the INVERSE focus distance t̂ = 1/𝔱 is modelled by
# a thin plate spline over nodes {𝐩_i} on the sensor ℐ = [0, W] × [0, H] (COLMAP pixels); where the nodes lie is their owner's
# choice (a calibration places them where the lens images light). `Focus(n, 𝔱, W, H)` below builds the plain sensor grid. Paper:
# "we model the depth 𝔱 not directly, instead we compute the inverse depth
# t̂: ℐ → ℝ, 𝐩 ↦ 1/t(𝐩)"), so that
#
#   𝔱(𝐩) = 1 / t̂(𝐩),      𝔣(𝐩) = 𝔭 + 𝔱(𝐩) π⁻¹(𝐩)   (radiometric_camera.jl)
# ---------------------------------------------------------------------------

"""
    Focus{T, N}

Inverse-depth focus surface: nodal values `t̂_i` (= `Θ_f`) on the TPS grid, the node
positions and the cached TPS coefficients `(w, a)`, `a = (a_1, a_x, a_y)`, for these values. Fully isbits —
the *solver* object (`FocusSpline`: VisualGeometryToolkitCore's spline system) stays host-side
(rebuilt by its owner at a parameter update).
"""
struct Focus{T, N}
    nodes::SVector{N, SVector{2, T}}
    t̂_i::SVector{N, T}
    w::SVector{N, T}
    a::SVector{3, T}
end

"""
    FocusSpline(nodes)

The host-side solver of a focus surface on `N` nodes of the sensor (pixels): VisualGeometryToolkitCore's `ThinPlateSplineSystem` of
the nodes. The host evaluates through the system (Core's `tps_coefficients`, `nodal_weights`); `coeff` is the system's map of nodal
values to `Focus`'s `(w; a₁, a_x, a_y)`, which the device evaluations convert to Float32.
"""
struct FocusSpline{N, S}
    sys::S
    nodes::SVector{N, SVector{2, Float64}}
    coeff::Matrix{Float64}                   # (N+3) × N
end
function FocusSpline(nodes::AbstractVector{<:StaticVector{2}})
    N = length(nodes)
    ns = SVector{N}(SVector{2, Float64}.(nodes))
    sys = VgtkCore.ThinPlateSplineSystem(collect(ns))
    return FocusSpline{N, typeof(sys)}(sys, ns, sys.coeff)
end
"""The host-side solver rebuilt from a focus's nodes."""
FocusSpline(f::Focus) = FocusSpline(SVector{2, Float64}.(f.nodes))

function Focus(tps::FocusSpline{N}, t̂_i::AbstractVector{T}) where {N, T}
    w, a = VgtkCore.tps_coefficients(tps.sys, t̂_i)
    return Focus{T, N}(SVector{N}(SVector{2, T}.(tps.nodes)), SVector{N, T}(t̂_i), SVector{N, T}(w), SVector{3, T}(a))
end

"""
    Focus(n, distance, W, H; T = Float64)

Constant focus surface `𝔱 ≡ distance` on the `n × n` grid of the sensor `[0, W] × [0, H]` (`t̂_i ≡ 1/distance`).
"""
Focus(n::Integer, distance::Real, W::Real, H::Real; T = Float64) =
    Focus(FocusSpline(grid_nodes(n, Rect(0, 0, W, H))), fill(T(1 / distance), n * n))

"""
    n_nodes(f::Focus) -> Int

The number of nodes of the focus surface's thin plate spline (the length of Θ_f, the nodal values of t̂).
"""
n_nodes(::Focus{T, N}) where {T, N} = N
Base.values(f::Focus) = f.t̂_i                                 # its nodal values t̂ᵢ (Base's `values`, extended: no Base name is shadowed)

"""
    inverse_focus_distance(f::Focus, 𝐩::StaticVector{2})

The inverse focus distance of the focus surface `f`, the paper's `t̂ = 1/𝔱` (public alias `t̂`), at the sensor position 𝐩 (COLMAP
pixels): the thin plate spline's value there.
"""
@inline inverse_focus_distance(f::Focus, 𝐩::StaticVector{2}) = VgtkCore.tps_evaluate(f.nodes, f.w, f.a, 𝐩)

"""
    focus_distance(f::Focus, 𝐩::StaticVector{2})

The focus distance along the chief ray of the sensor position 𝐩, the paper's `𝔱(𝐩) = 1/t̂(𝐩)` (public alias `𝔱`).
"""
@inline focus_distance(f::Focus, 𝐩::StaticVector{2}) = 1 / inverse_focus_distance(f, 𝐩)

# VisualGeometryToolkitCore's parameter protocol of a focus surface: its nodal values t̂ᵢ (unbounded; an estimator's box keeps them ≥ 0),
# rebuilt through its host-side spline system; and its element-type conversion (element types only, no TPS solve)
parameter_vector(f::Focus) = f.t̂_i
parameter_names(::Focus{T, N}) where {T, N} = ntuple(i -> Symbol(:t̂, i), N)
with_parameters(f::Focus, θ) = Focus(FocusSpline(f), θ)
VgtkCore.local_coordinates(ch::VgtkCore.ParameterManifold, f::Focus) = VgtkCore.parameter_offsets(ch, f)   # its chart coordinates on a ParameterManifold
function convert_eltype(::Type{T}, f::Focus{S, N}) where {T, S, N}
    nodes = map(n -> SVector{2, T}(n), f.nodes)
    return Focus{T, N}(nodes, map(T, f.t̂_i), map(T, f.w), map(T, f.a))
end

# The paper's notation, as public aliases of the same functions (one definition each)
const t̂ = inverse_focus_distance
const 𝔱 = focus_distance

# ---- removed: the focus surfaces on the chief directions (a thin plate spline in the azimuthal-equidistant chart, a spherical
# spline). The focus surface is the thin plate spline over the sensor; the removed call forms and names are refused by name.
_removed_focus_kind(what) = throw(ArgumentError(
    "$what was removed with the focus surfaces on the chief directions: the focus surface is the thin plate spline over the sensor"))
FocusSpline(::AbstractVector{<:StaticVector{2}}, kind::Integer) =
    _removed_focus_kind("FocusSpline(nodes, kind) (a focus kind; the solver is `FocusSpline(nodes)`, its nodes sensor positions in pixels)")
inverse_focus_distance(::Focus, ::StaticVector{3}) =
    _removed_focus_kind("inverse_focus_distance(focus, direction) (the surface is read at a sensor position: `inverse_focus_distance(focus, 𝐩)`)")
focus_weights(args...; kwargs...) =
    _removed_focus_kind("focus_weights (the nodal weights at a sensor position are VisualGeometryToolkitCore's `nodal_weights(FocusSpline(focus).sys, 𝐩)`)")
polar_cap_nodes(args...; kwargs...) = _removed_focus_kind("polar_cap_nodes")

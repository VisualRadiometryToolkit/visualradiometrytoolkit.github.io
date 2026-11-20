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
    kind::Int          # EXPERIMENT (focus-ab): 0 sensor TPS (pixels), 1 direction-chart TPS, 2 spherical spline (focus_charts.jl)
end
Focus{T, N}(nodes, t̂_i, w, a) where {T, N} = Focus{T, N}(nodes, t̂_i, w, a, 0)

"""
    FocusSpline(nodes[, kind = 0])

The host-side solver of a focus surface on `N` nodes: VisualGeometryToolkitCore's `ThinPlateSplineSystem` of the nodes (kind 0: the
sensor (pixels); kind 1, EXPERIMENT focus-ab: the azimuthal-equidistant direction chart) or its `SphericalSplineSystem` of their directions
(kind 2). The host evaluates through the system (Core's `tps_coefficients` / `spherical_spline_coefficients`, `nodal_weights`);
`coeff` is the map of nodal values to `Focus`'s `(w; a₁, a_x, a_y)` in one layout for every kind (the sphere's constant-only map padded
with two zero rows), which the device evaluations convert to Float32.
"""
struct FocusSpline{N, S}
    sys::S
    nodes::SVector{N, SVector{2, Float64}}
    coeff::Matrix{Float64}                   # (N+3) × N
    kind::Int
end
function FocusSpline(nodes::AbstractVector{<:StaticVector{2}}, kind::Integer = 0)
    N = length(nodes)
    ns = SVector{N}(SVector{2, Float64}.(nodes))
    if kind == 2
        sys = VgtkCore.SphericalSplineSystem([ae_dir(n) for n in ns])
        return FocusSpline{N, typeof(sys)}(sys, ns, vcat(sys.coeff, zeros(2, N)), 2)
    end
    sys = VgtkCore.ThinPlateSplineSystem(collect(ns))
    return FocusSpline{N, typeof(sys)}(sys, ns, sys.coeff, Int(kind))
end
"""The host-side solver rebuilt from a focus's nodes and kind."""
FocusSpline(f::Focus) = FocusSpline(SVector{2, Float64}.(f.nodes), f.kind)

function Focus(tps::FocusSpline{N}, t̂_i::AbstractVector{T}) where {N, T}
    w, a = _focus_coefficients(tps.sys, t̂_i)
    return Focus{T, N}(SVector{N}(SVector{2, T}.(tps.nodes)), SVector{N, T}(t̂_i), SVector{N, T}(w), SVector{3, T}(a), tps.kind)
end
# (w, a) through the nodal values: Core's coefficient maps; the sphere's constant-only spline has a_x = a_y = 0
_focus_coefficients(sys::VgtkCore.ThinPlateSplineSystem, t) = VgtkCore.tps_coefficients(sys, t)
_focus_coefficients(sys::VgtkCore.SphericalSplineSystem, t) =
    ((w, a₁) = VgtkCore.spherical_spline_coefficients(sys, t); (w, SVector(a₁, zero(a₁), zero(a₁))))

"""
    Focus(n, focus_distance, W, H; T = Float64)

Constant focus surface `𝔱 ≡ focus_distance` on the `n × n` grid of the sensor `[0, W] × [0, H]` (`t̂_i ≡ 1/focus_distance`).
"""
Focus(n::Integer, focus_distance::Real, W::Real, H::Real; T = Float64) =
    Focus(FocusSpline(grid_nodes(n, Rect(0, 0, W, H))), fill(T(1 / focus_distance), n * n))

"""
    n_nodes(f::Focus) -> Int

The number of nodes of the focus surface's thin plate spline (the length of Θ_f, the nodal values of t̂).
"""
n_nodes(::Focus{T, N}) where {T, N} = N
Base.values(f::Focus) = f.t̂_i                                 # its nodal values t̂ᵢ (Base's `values`, extended: no Base name is shadowed)

"""`t̂(𝐩)` — inverse focus distance at sensor position 𝐩."""
@inline t̂(f::Focus, 𝐩::StaticVector{2}) = VgtkCore.tps_evaluate(f.nodes, f.w, f.a, 𝐩)

"""`𝔱(𝐩) = 1/t̂(𝐩)` — focus distance along the chief ray of 𝐩."""
@inline 𝔱(f::Focus, 𝐩::StaticVector{2}) = 1 / t̂(f, 𝐩)

# VisualGeometryToolkitCore's parameter protocol of a focus surface: its nodal values t̂ᵢ (unbounded; an estimator's box keeps them ≥ 0),
# rebuilt through its host-side spline system; and its element-type conversion (element types only, no TPS solve)
parameter_vector(f::Focus) = f.t̂_i
parameter_names(::Focus{T, N}) where {T, N} = ntuple(i -> Symbol(:t̂, i), N)
with_parameters(f::Focus, θ) = Focus(FocusSpline(f), θ)
function convert_eltype(::Type{T}, f::Focus{S, N}) where {T, S, N}
    nodes = map(n -> SVector{2, T}(n), f.nodes)
    return Focus{T, N}(nodes, map(T, f.t̂_i), map(T, f.w), map(T, f.a), f.kind)
end

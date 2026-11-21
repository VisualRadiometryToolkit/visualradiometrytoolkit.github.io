# ---------------------------------------------------------------------------
# The printed edge (targets with a distance map `TexturedTarget.sdf`): the ink coverage of a board point is a Gaussian edge
#
#   ink(𝐛) = Φ( (δ − d(𝐛)) / σ_print ),   ρ = 1 − ink,
#
# Φ = VisualGeometryToolkitCore's `normcdf_as` (Abramowitz & Stegun 7.1.26; a dual's derivative is the approximation's, the pathwise
# Jacobian of the evaluated objective), d(𝐛) = signed distance [mm] to the nearest ink edge of the DESIGN (+ on paper), δ = ink spread [mm] (the printed line
# width grows by 2δ), σ_print = the blur of the print [mm]. The defocus disc is the aperture integral's. δ and σ_print are the
# print's, the target's state (`TargetState.edge`; `ink_spread`, `print_blur`).
# ---------------------------------------------------------------------------

const EDGE_EPS_MM = 1e-4                       # floor of σ_c [mm] (a step edge without blur would be a δ-function derivative)

"""
    edge_albedo(target, 𝐛) -> SVector{3}

Albedo `1 − Φ((δ − d)/σ_print)` of the printed edge at chart 𝐛 (see the file header), the same in every channel: δ the target's
[`ink_spread`](@ref), σ_print its [`print_blur`](@ref) (its state's `edge`). The derivative w.r.t. 𝐛 flows through the distance map
(bilinear), w.r.t. the print's parameters through the state.
"""
@inline edge_albedo(bd::TexturedTarget, 𝐛::StaticVector{2}) = _edge_profile(bd.state.edge, VgtkCore.bilinear_sample(bd.sdf, 𝐛))
"""The printed edge's albedo at the signed distance `d` [mm] (`edge_albedo`'s profile) under the print's parameters `e = (δ, σ_print)`."""
@inline function _edge_profile(e::StaticVector{EDGE_NC}, d)
    δ = e[1]; σp = e[2]
    e2 = oftype(ForwardDiff.value(d), EDGE_EPS_MM)^2
    ρ = 1 - VgtkCore.normcdf_as((δ - d) / sqrt(σp * σp + e2))
    return SVector(ρ, ρ, ρ)
end

# (dispatch on the FIELD type: a method on `TexturedTarget{T, Q, A3, Nothing} where {T, Q, A3}` is not preferred over one on
# `TexturedTarget` — Julia's specificity rules with the struct's bounded parameters — so every no-map target took the edge path)
"""
    printed_albedo(target, 𝐛) -> SVector{3}

Albedo of a point of the target as printed, at the page chart 𝐛: its texture's ([`albedo`](@ref)), or the printed-edge model's
([`edge_albedo`](@ref)) on a target with a distance map.
"""
@inline printed_albedo(bd::TexturedTarget, 𝐛::StaticVector{2}) = _printed_albedo(bd.sdf, bd, 𝐛)
@inline _printed_albedo(::Nothing, bd::TexturedTarget, 𝐛::StaticVector{2}) = albedo(bd, 𝐛)
@inline _printed_albedo(::AbstractMatrix, bd::TexturedTarget, 𝐛::StaticVector{2}) = edge_albedo(bd, 𝐛)

"""
    physical_albedo(target, 𝐛) -> SVector{3}

Albedo of the target as printed at the PHYSICAL page chart 𝐛 (where a surface point lies, `chart`): [`printed_albedo`](@ref) at the
design point that 𝐛 shows under the target's in-plane print error ([`design_chart`](@ref)). What a renderer reads at a ray's hit.
"""
@inline physical_albedo(bd::TexturedTarget, 𝐛::StaticVector{2}) = printed_albedo(bd, design_chart(bd, 𝐛))

"""
    anchored_albedo(target, 𝐱₀, δ𝐱) -> SVector{3}

[`physical_albedo`](@ref) at the surface point `𝐱₀ + δ𝐱` (world) given as an ANCHOR `𝐱₀` and an OFFSET `δ𝐱`: evaluated in the anchor's
precision, returned in the offset's numbers. The re-centred lookup of a kernel whose numbers are coarser than the print's detail:
a Float32 world point is ≈ 0.06 µm coarse a metre from the origin, 0.2 % of a printed edge's 0.03 mm blur, and the edge's slope there
moves by ≈ 1 %. With a hit found once in Float64 as the anchor and a kernel's Float32 duals as the offset (their partials; the value
zero, or a small step), the chart, the design chart (its in-plane print error's map included: `exp` of a Float32 log-stretch is
off by as much) and the maps' lookups keep the anchor's precision.

`target` holds the page and its maps in the anchor's float (`convert_eltype`) and its state in any numbers (`with_state`: a
kernel's duals); the result's numbers are those of the offset and the state (`promote_type` of their element types). Only the point
and the map's read are in the anchor's precision: the read (a texture's albedo, a distance map's signed distance, small near an
edge) is rounded to the offset's numbers before the printed edge's profile.
"""
@inline function anchored_albedo(bd::TexturedTarget, 𝐱₀::StaticVector{3}, δ𝐱::StaticVector{3})
    # the in-plane print error's map in the anchor's precision too: its factors (eᵃ) in a kernel's Float32 move the point as much
    θ = bd.state.inplane
    𝐛 = design_chart(bd, SVector{INPLANE_NC, promote_type(eltype(θ), eltype(𝐱₀))}(θ), chart(bd, 𝐱₀ + δ𝐱))
    R = promote_type(eltype(δ𝐱), eltype(bd.state.h))
    return _anchored_albedo(bd.sdf, bd, 𝐛, R)
end
@inline _anchored_albedo(::Nothing, bd::TexturedTarget, 𝐛, ::Type{R}) where {R} = SVector{3, R}(albedo(bd, 𝐛))
@inline _anchored_albedo(sdf::AbstractMatrix, bd::TexturedTarget, 𝐛, ::Type{R}) where {R} =
    SVector{3, R}(_edge_profile(bd.state.edge, convert(R, VgtkCore.bilinear_sample(sdf, 𝐛))))

"""
    has_sdf(target) -> Bool

Whether a target carries the printed-edge model (a distance map).
"""
@inline has_sdf(bd::TexturedTarget) = !(bd.sdf isa Nothing)

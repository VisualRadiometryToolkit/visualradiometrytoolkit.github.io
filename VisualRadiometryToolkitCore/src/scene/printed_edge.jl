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
@inline function edge_albedo(bd::TexturedTarget, 𝐛::StaticVector{2})
    d = VgtkCore.bilinear_sample(bd.sdf, 𝐛)                                  # the signed distance [mm] (Core's bilinear read)
    e = bd.state.edge
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
    has_sdf(target) -> Bool

Whether a target carries the printed-edge model (a distance map).
"""
@inline has_sdf(bd::TexturedTarget) = !(bd.sdf isa Nothing)

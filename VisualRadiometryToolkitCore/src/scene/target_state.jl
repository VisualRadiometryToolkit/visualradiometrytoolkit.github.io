# ---------------------------------------------------------------------------
# A textured target's OWN state: what a calibration learns about one printed target beyond its design.
#
#   h        the out-of-plane shape of the page: HEIGHT_N × HEIGHT_N nodal heights of VisualGeometryToolkitCore's `HeightField` over
#            the page (world units along the target's normal, z > 0 towards the camera); all zero = the plane (target_warping.jl)
#   edge     the printed edge of a target whose design is a distance map: (ink spread δ, print blur σ_print), mm (printed_edge.jl)
#   inplane  the in-plane print error (a, u) of VisualGeometryToolkitCore's `Aspect ∘ Skew` (target_warping.jl); zero = as designed
#
# The state is a field of the target (`TexturedTarget.state`), isbits and BY VALUE, in its own element type: a renderer's kernel
# holds the target's arrays on the device and replaces the state with the numbers it differentiates (`with_state(target, state)`:
# dual numbers in the nodal heights, Float32 on a device), without touching the arrays.
# ---------------------------------------------------------------------------

"""
    EDGE_NC = 2

The number of printed-edge parameters of a [`TargetState`](@ref) (`edge`: the ink spread δ [mm] and the print's blur `σ_print`
[mm], read by [`edge_albedo`](@ref)).
"""
const EDGE_NC = 2
const HEIGHT_N = 5                                                                  # nodes per page axis
"""
    HEIGHT_NC = 25

The number of nodal heights of the board warping h (`TargetState.h`): Core's `HeightField` through a 5 × 5 node grid over the page,
heights in world units along the board normal. Three combinations of them (the piston and the two tilts) are a pose's, so a
calibration has `HEIGHT_NC − 3` free ones.
"""
const HEIGHT_NC = HEIGHT_N * HEIGHT_N
"""
    INPLANE_NC = 2

The number of parameters of the in-plane print error of the board (`TargetState.inplane`): the log-stretch `a` of Core's `Aspect`
(x by eᵃ, y by e⁻ᵃ; `a = 0.001` stretches x by 0.1 % against y) and the shear `u` of Core's `Skew` (`x ↦ x + u y`), both in the
warping's placed chart (the page in units of its width, y up).
"""
const INPLANE_NC = 2
"""
    TargetState{T}

The state of a [`TexturedTarget`](@ref) (its field `state`): the warping `h` (the `HEIGHT_NC` nodal heights of the thin plate spline, `board_height`;
all zero = the plane), the printed edge `edge = (δ [mm], σ_print [mm])` — the ink spread ([`ink_spread`](@ref)) and the print's blur
([`print_blur`](@ref)) — of a target with a distance map
(`TexturedTarget.sdf`, `edge_albedo`; unused otherwise) and the in-plane print error `inplane = (a, u)` (`inplane_calibration`,
Core's `Aspect ∘ Skew`; zero = the design as printed). `TargetState()` is the plane with no edge parameters, printed as designed. Its parts are replaced by
[`with_h`](@ref), [`with_edge`](@ref) and [`with_inplane`](@ref), on a state or on the target that holds it.
"""
struct TargetState{T}
    h::SVector{HEIGHT_NC, T}
    edge::SVector{EDGE_NC, T}
    inplane::SVector{INPLANE_NC, T}
end
TargetState{T}() where {T} = TargetState{T}(zero(SVector{HEIGHT_NC, T}), zero(SVector{EDGE_NC, T}), zero(SVector{INPLANE_NC, T}))
function TargetState(; h = nothing, edge = nothing, inplane = nothing, T = nothing)
    Tv = T !== nothing ? T : h !== nothing ? float(eltype(h)) : edge !== nothing ? float(eltype(edge)) : inplane !== nothing ? float(eltype(inplane)) : Float64
    hv = h === nothing ? zero(SVector{HEIGHT_NC, Tv}) : SVector{HEIGHT_NC, Tv}(h)
    ev = edge === nothing ? zero(SVector{EDGE_NC, Tv}) : SVector{EDGE_NC, Tv}(edge)
    iv = inplane === nothing ? zero(SVector{INPLANE_NC, Tv}) : SVector{INPLANE_NC, Tv}(inplane)
    return TargetState{Tv}(hv, ev, iv)
end
"""
    with_h(state::TargetState, h) -> TargetState
    with_h(target::TexturedTarget, h) -> TexturedTarget

The state (or the target, in its state) with the nodal heights of the warping replaced.
"""
with_h(s::TargetState{T}, h) where {T} = TargetState{T}(SVector{HEIGHT_NC, T}(h), s.edge, s.inplane)
"""
    with_edge(state::TargetState, edge) -> TargetState
    with_edge(target::TexturedTarget, edge) -> TexturedTarget

The state (or the target, in its state) with the printed edge `(ink spread δ, print blur σ_print)` in mm replaced
([`edge_albedo`](@ref)).
"""
with_edge(s::TargetState{T}, edge) where {T} = TargetState{T}(s.h, SVector{EDGE_NC, T}(edge), s.inplane)
"""
    with_inplane(state::TargetState, θ) -> TargetState
    with_inplane(target::TexturedTarget, θ) -> TexturedTarget

The state (or the target, in its state) with the in-plane print error `(a, u)` replaced ([`inplane_calibration`](@ref)).
"""
with_inplane(s::TargetState{T}, θ) where {T} = TargetState{T}(s.h, s.edge, SVector{INPLANE_NC, T}(θ))
"""
    height_on(state::TargetState) -> Bool
    height_on(target::TexturedTarget) -> Bool

Whether the target is warped; all nodal heights zero (the default) = the plane.
"""
@inline height_on(s::TargetState) = !iszero(s.h)
"""Whether the surface carries an in-plane print error (`inplane_on` of its parameters)."""
@inline inplane_on(s::TargetState) = inplane_on(s.inplane)
convert_eltype(::Type{T}, s::TargetState) where {T} =
    TargetState{T}(SVector{HEIGHT_NC, T}(s.h), SVector{EDGE_NC, T}(s.edge), SVector{INPLANE_NC, T}(s.inplane))


"""
    ink_spread(state::TargetState)
    ink_spread(target::TexturedTarget)

The ink spread δ of the printed edge, in mm (`edge[1]`): the printed line width grows by 2δ ([`edge_albedo`](@ref)).
"""
@inline ink_spread(s::TargetState) = s.edge[1]
"""
    print_blur(state::TargetState)
    print_blur(target::TexturedTarget)

The blur σ_print of the print, in mm (`edge[2]`): the standard deviation of the printed edge's Gaussian ([`edge_albedo`](@ref)).
"""
@inline print_blur(s::TargetState) = s.edge[2]

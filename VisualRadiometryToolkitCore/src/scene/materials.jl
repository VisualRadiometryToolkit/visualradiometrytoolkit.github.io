# ---------------------------------------------------------------------------
# Spatially varying Cook–Torrance BSDF (paper §SVBSDF and Monte Carlo Estimation):
#
#   f_c^CT(𝐱, ω, ω′; Θ_m) = μ ρ_c(𝐱)/π
#        + (1−μ) F_c(ω, ω_h; η_c) D(ω_h; α) G_2(ω, ω′) / (4 cos θ(ω) cos θ(ω′))
#
#   D    GGX normal distribution,  G_2 height-correlated Smith masking–shadowing,
#   F_c  exact unpolarised dielectric Fresnel term with refractive index η_c,
#   w(𝐛) = texture value = luma(ρ(𝐛)) ∈ [0, 1] (1 = no ink),  α(𝐛) = w α_¬ink + (1−w) α_ink,  η(𝐛) = w η_¬ink + (1−w) η_ink
#   (paper: "using the texture value to blend between α_ink and α_¬ink, η_ink and η_¬ink" — the coverage of a
#   printed texel is linear in its albedo, so the microfacet mix is linear in the texture value)
#
#   Θ_m = {α_¬ink, α_ink, η_¬ink, η_ink, μ}: Θ_m ∖ {μ} = 8 nonlinear parameters (η per channel), μ affine in the flux.
#
# Microfacet normals are sampled from the GGX distribution of visible normals
# D^v(𝐧, ω; α) with the spherical-caps method (Dupuy & Benyoub 2023) and turned
# into directions by the reflection ω′ = 2(ω⋅𝐧)𝐧 − ω, PDF(𝐧, ω; α) = D^v/(4 ω⋅𝐧).
# All directions in this file are in the LOCAL board frame (z = board normal).
# ---------------------------------------------------------------------------

"""
    Material{T}

`Θ_m`: the roughness endpoints `roughness_ink`, `roughness_paper` (the paper's `α_ink`, `α_¬ink`), the refractive indices
`refractive_index_ink`, `refractive_index_paper` (`η_ink`, `η_¬ink`, per channel) and the diffuse/specular weight `diffuse_weight` (`μ`);
the ink ↔ no-ink blend weight of a board point is its texture value (`texture_weight`). `Material(; roughness_ink, roughness_paper,
refractive_index_ink, refractive_index_paper, diffuse_weight)` builds it from scalars (an index is repeated on the three channels).
"""
struct Material{T}
    roughness_ink::T
    roughness_paper::T
    refractive_index_ink::SVector{3, T}
    refractive_index_paper::SVector{3, T}
    diffuse_weight::T
end
function Material(roughness_ink, roughness_paper, refractive_index_ink::AbstractVector, refractive_index_paper::AbstractVector, diffuse_weight)
    T = promote_type(typeof(roughness_ink), typeof(roughness_paper), eltype(refractive_index_ink), eltype(refractive_index_paper), typeof(diffuse_weight))
    return Material{T}(T(roughness_ink), T(roughness_paper), SVector{3, T}(refractive_index_ink), SVector{3, T}(refractive_index_paper), T(diffuse_weight))
end
Material(; roughness_ink = 0.15, roughness_paper = 0.4, refractive_index_ink = 1.6, refractive_index_paper = 1.33, diffuse_weight = 0.5) =
    Material(roughness_ink, roughness_paper, SVector(refractive_index_ink, refractive_index_ink, refractive_index_ink) .* 1.0, SVector(refractive_index_paper, refractive_index_paper, refractive_index_paper) .* 1.0, diffuse_weight)

"""
    nonlinear_parameters(m::Material) -> SVector{8}

The material's nonlinear parameters, the paper's `Θ_m ∖ {μ}` (public alias `Θ_m_nonlinear`), in the order `roughness_ink,
roughness_paper, refractive_index_ink[1:3], refractive_index_paper[1:3]`.
"""
nonlinear_parameters(m::Material{T}) where {T} = SVector{8, T}(m.roughness_ink, m.roughness_paper, m.refractive_index_ink..., m.refractive_index_paper...)
"""
    with_nonlinear(m::Material, θ::StaticVector{8}) -> Material

The material `m` with its nonlinear parameters `Θ_m ∖ {μ}` replaced by `θ`, in the order of [`nonlinear_parameters`](@ref)
(`roughness_ink, roughness_paper, refractive_index_ink[1:3], refractive_index_paper[1:3]`); the diffuse weight is kept, so
`with_nonlinear(m, nonlinear_parameters(m)) == m`.
"""
with_nonlinear(m::Material, θ::StaticVector{8}) = Material(θ[1], θ[2], SVector(θ[3], θ[4], θ[5]), SVector(θ[6], θ[7], θ[8]), m.diffuse_weight)
"""
    with_diffuse_weight(m::Material, μ) -> Material

The material `m` with the diffuse weight `μ` (the field `diffuse_weight`; public alias `with_μ`; dimensionless, `f_c^CT = μ ρ_c/π + (1 − μ)` × the specular term); the roughnesses and
the indices of refraction are kept.
"""
with_diffuse_weight(m::Material, μ) = Material(m.roughness_ink, m.roughness_paper, m.refractive_index_ink, m.refractive_index_paper, μ)
"""
    diffuse_weight(m::Material) -> Real

The material's diffuse weight μ (the share of the diffuse lobe; `1 − μ` is the specular share).
"""
diffuse_weight(m::Material) = m.diffuse_weight
convert_eltype(::Type{T}, m::Material) where {T} = Material(T(m.roughness_ink), T(m.roughness_paper), SVector{3, T}(m.refractive_index_ink), SVector{3, T}(m.refractive_index_paper), T(m.diffuse_weight))

"""Ink ↔ no-ink blend weight of a board point: the texture value `w = luma(ρ(𝐛))` clamped to [0, 1] (1 = no ink, 0 = ink)."""
@inline texture_weight(ρ::StaticVector{3}) = clamp(luma(ρ), 0, 1)
"""Spatially varying roughness `α(𝐛) = w α_¬ink + (1−w) α_ink` at the blend weight `w = texture_weight(ρ)` (the paper's `α`; public alias `𝛂`)."""
@inline roughness(m::Material, w) = w * m.roughness_paper + (1 - w) * m.roughness_ink
"""Spatially varying refractive indices `η_c(𝐛) = w η_¬ink + (1−w) η_ink` at the blend weight `w` (the paper's `η`; public alias `𝛈`)."""
@inline refractive_index(m::Material, w) = w * m.refractive_index_paper + (1 - w) * m.refractive_index_ink

"""GGX normal distribution, the paper's `D(ω_h; α)` (`cosθ_h = ω_h ⋅ 𝐧`)."""
@inline function ggx_distribution(α, cosθ_h)
    cosθ_h <= 0 && return zero(cosθ_h * α)
    t = cosθ_h^2 * (α^2 - 1) + 1
    return α^2 / (π * t^2)
end

"""Smith Λ for GGX at `cosθ = ω ⋅ 𝐧` (public alias `Λ_ggx`)."""
@inline function ggx_lambda(α, cosθ)
    T = typeof(α * cosθ)
    μ² = max(cosθ^2, sqrt(eps(T)) * T(1//1000))
    return (sqrt(1 + α^2 * (1 - μ²) / μ²) - 1) / 2
end
"""Smith masking of one direction, `G_1(ω) = 1/(1 + Λ(ω))`."""
@inline ggx_masking(α, cosθ) = 1 / (1 + ggx_lambda(α, cosθ))
"""Height-correlated `G_2(ω, ω′) = 1/(1 + Λ(ω) + Λ(ω′))` (Heitz 2014)."""
@inline ggx_masking_shadowing(α, cosθ, cosθ′) = 1 / (1 + ggx_lambda(α, cosθ) + ggx_lambda(α, cosθ′))

"""
    fresnel_dielectric(η, c) 

Exact unpolarised dielectric Fresnel reflectance for `c = |ω ⋅ ω_h|` and refractive index `η`.
"""
@inline function fresnel_dielectric(η, c)
    g² = η^2 - 1 + c^2
    g² <= 0 && return one(g²)                    # total internal reflection
    g = sqrt(g²)
    a = (g - c) / (g + c)
    b = (c * (g + c) - 1) / (c * (g - c) + 1)
    return a^2 / 2 * (1 + b^2)
end

"""
    sample_visible_normal(α, ω, u₁, u₂) -> 𝐧

Microfacet normal `𝐧 ~ D^v(⋅, ω; α)` by the spherical-caps method (local frame, `ω_z > 0`).
"""
@inline function sample_visible_normal(α, ω::StaticVector{3}, u₁, u₂)
    i = SVector(α * ω[1], α * ω[2], ω[3])
    i = i / sqrt(dot(i, i))
    φ = 2 * typeof(u₁)(π) * u₁
    z = (1 - u₂) * (1 + i[3]) - i[3]
    s = sqrt(max(1 - z^2, eps(typeof(ForwardDiff.value(z)))))       # ε floor: keeps the derivative finite at the cap pole
    o = SVector(s * cos(φ), s * sin(φ), z)
    m = i + o
    n = SVector(α * m[1], α * m[2], m[3])
    return n / sqrt(dot(n, n))
end

"""Visible-normal density `D^v(𝐧, ω; α) = G_1(ω) max(0, ω⋅𝐧) D(𝐧) / cosθ(ω)`."""
@inline function visible_normal_density(α, 𝐧::StaticVector{3}, ω::StaticVector{3})
    ωn = dot(ω, 𝐧)
    return ggx_masking(α, ω[3]) * max(ωn, zero(ωn)) * ggx_distribution(α, 𝐧[3]) / ω[3]
end

"""PDF of the reflected direction ω′ = 2(ω⋅𝐧)𝐧 − ω: `D^v(𝐧, ω; α)/(4 ω⋅𝐧)`."""
@inline reflection_pdf(α, 𝐧::StaticVector{3}, ω::StaticVector{3}) = visible_normal_density(α, 𝐧, ω) / (4 * dot(ω, 𝐧))

"""Reflection of ω about the microfacet normal 𝐧."""
@inline reflect(ω::StaticVector{3}, 𝐧::StaticVector{3}) = 2 * dot(ω, 𝐧) * 𝐧 - ω

"""
    cook_torrance_terms(ρ, α, η, ω, ω′, 𝐧_h) -> (diffuse::SVector{3}, specular::SVector{3})

The two terms of `f_c^CT` **without** the μ weights: `ρ_c/π` and
`F_c D G_2 / (4 cosθ cosθ′)`, so `f_c^CT = μ ⋅ diffuse + (1−μ) ⋅ specular`.
"""
@inline function cook_torrance_terms(ρ::StaticVector{3}, α, η::StaticVector{3}, ω::StaticVector{3}, ω′::StaticVector{3}, 𝐧_h::StaticVector{3})
    cosθ = ω[3]; cosθ′ = ω′[3]
    c = abs(dot(ω, 𝐧_h))
    ϵ = sqrt(eps(typeof(ForwardDiff.value(cosθ))))
    k = ggx_distribution(α, 𝐧_h[3]) * ggx_masking_shadowing(α, cosθ, cosθ′) / (4 * max(cosθ, ϵ) * max(cosθ′, ϵ))
    spec = SVector(fresnel_dielectric(η[1], c), fresnel_dielectric(η[2], c), fresnel_dielectric(η[3], c)) * k
    return ρ / π, spec
end

"""The Cook–Torrance BSDF, the paper's `f_c^CT`, for all channels: `diffuse_weight` × the diffuse term + `(1 − diffuse_weight)` × the specular term of [`cook_torrance_terms`](@ref)."""
@inline function cook_torrance(m::Material, ρ, α, η, ω, ω′, 𝐧_h)
    d, s = cook_torrance_terms(ρ, α, η, ω, ω′, 𝐧_h)
    return m.diffuse_weight * d + (1 - m.diffuse_weight) * s
end

# The paper's notation, as public aliases: each is the SAME function as the descriptive name (one definition, no second method table).
const Θ_m_nonlinear = nonlinear_parameters
const with_μ = with_diffuse_weight
const 𝛂 = roughness
const 𝛈 = refractive_index
const Λ_ggx = ggx_lambda

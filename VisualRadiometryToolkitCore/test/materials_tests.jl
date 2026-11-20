# A surface's reflectance (scene/materials.jl): the Cook–Torrance BSDF and its GGX pieces. Moved with the code from the BSDF part
# of RadiometricCamera's test/unit/bsdf_radiance_tests.jl (its Monte-Carlo radiance part stays there, with the sampler).

@testitem "materials: the Cook–Torrance BSDF and its GGX pieces" begin
    using Test
    using VisualRadiometryToolkitCore: Material, Θ_m_nonlinear, with_nonlinear, with_μ, texture_weight, 𝛂, 𝛈, D_ggx, Λ_ggx, G1_ggx, G2_ggx,
                                       F_dielectric, sample_vndf_caps, D_v, PDF_reflect, reflect, f_CT_parts, f_CT
    using StaticArrays: SVector
    using LinearAlgebra: dot, normalize, norm
    import ForwardDiff
    import VisualGeometryToolkitCore as VgtkCore

    @test F_dielectric(1.5, 1.0) ≈ ((1.5 - 1) / (1.5 + 1))^2
    @test F_dielectric(1.5, 0.0) ≈ 1
    # GGX normalisation ∫ D cosθ dω = 1
    nθ = 4000
    @test sum(D_ggx(0.3, cos(θ)) * cos(θ) * sin(θ) * (π / 2 / nθ) * 2π for θ in ((i - 0.5) * (π / 2) / nθ for i in 1:nθ)) ≈ 1 atol = 1e-3
    @test G2_ggx(0.5, 0.7, 0.4) <= min(G1_ggx(0.5, 0.7), G1_ggx(0.5, 0.4))
    @test G1_ggx(0.3, 1.0) ≈ 1 && G1_ggx(0.3, 0.6) == 1 / (1 + Λ_ggx(0.3, 0.6))
    # VNDF sampler ↔ density: E_{𝐧∼D^v}[ h(𝐧) / D^v(𝐧) ] = ∫_{𝐧_z>0, ω⋅𝐧>0} h d𝐧  (D^v integrates to one on the visible set);
    # the sampler's uniforms are VisualGeometryToolkitCore's Hammersley points
    ω = normalize(SVector(0.3, 0.1, 1.0)); α = 0.35
    N = 40000
    acc = sum(1:N) do i
        u1, u2 = VgtkCore.hammersley(i, N)
        n = sample_vndf_caps(α, ω, u1, u2)
        n[3] / D_v(α, n, ω)
    end
    nθ_v, nφ_v = 400, 800
    dirs = [(θ = (i - 0.5) * (π / 2) / nθ_v; φ = (j - 0.5) * 2π / nφ_v; (SVector(sin(θ) * cos(φ), sin(θ) * sin(φ), cos(θ)), sin(θ) * (π / 2 / nθ_v) * (2π / nφ_v)))
            for i in 1:nθ_v, j in 1:nφ_v]
    ref_vis = sum(((n, dω),) -> dot(ω, n) > 0 ? n[3] * dω : 0.0, dirs)
    @test acc / N ≈ ref_vis rtol = 0.02
    # density integrates to one over the visible normals
    @test sum(((n, dω),) -> D_v(α, n, ω) * dω, dirs) ≈ 1 rtol = 5e-3
    # the reflected direction and its density
    n = sample_vndf_caps(α, ω, 0.3, 0.6); ω′ = reflect(ω, n)
    @test norm(ω′) ≈ 1 && dot(ω′, n) ≈ dot(ω, n) && PDF_reflect(α, n, ω) == D_v(α, n, ω) / (4 * dot(ω, n))

    # the material: Θ_m, its nonlinear part and μ replaced, the ink ↔ no-ink blend by the texture value
    m = Material(; 𝛂_ink = 0.12, 𝛂_noink = 0.35, 𝛈_ink = 1.65, 𝛈_noink = 1.33, μ = 0.6)
    θ = Θ_m_nonlinear(m)
    @test θ == SVector(0.12, 0.35, 1.65, 1.65, 1.65, 1.33, 1.33, 1.33) && with_nonlinear(m, θ) == m && isbits(m)
    @test with_μ(m, 0.25).μ == 0.25 && with_μ(m, 0.25).𝛂_ink == m.𝛂_ink
    @test texture_weight(SVector(1.0, 1.0, 1.0)) ≈ 1 && texture_weight(SVector(0.0, 0.0, 0.0)) == 0 && texture_weight(SVector(2.0, 2.0, 2.0)) == 1
    @test 𝛂(m, 1.0) == m.𝛂_noink && 𝛂(m, 0.0) == m.𝛂_ink && 𝛈(m, 0.5) ≈ (m.𝛈_ink + m.𝛈_noink) / 2
    m32 = VgtkCore.convert_eltype(Float32, m)
    @test m32 isa Material{Float32} && m32.μ === 0.6f0
    # f_CT = μ · diffuse + (1 − μ) · specular; reciprocal; dual-generic in the roughness
    ρ = SVector(0.8, 0.5, 0.3); w = texture_weight(ρ); αb = 𝛂(m, w); ηb = 𝛈(m, w)
    ω_o = normalize(SVector(-0.4, 0.3, 1.0)); ω_i = normalize(SVector(0.2, 0.5, 0.7)); h = normalize(ω_o + ω_i)
    d, s = f_CT_parts(ρ, αb, ηb, ω_o, ω_i, h)
    @test d == ρ / π && f_CT(m, ρ, αb, ηb, ω_o, ω_i, h) ≈ m.μ * d + (1 - m.μ) * s
    @test f_CT(m, ρ, αb, ηb, ω_i, ω_o, h) ≈ f_CT(m, ρ, αb, ηb, ω_o, ω_i, h)
    g = ForwardDiff.derivative(a -> f_CT(m, ρ, a, ηb, ω_o, ω_i, h)[1], αb)
    @test g ≈ (f_CT(m, ρ, αb + 1e-6, ηb, ω_o, ω_i, h)[1] - f_CT(m, ρ, αb - 1e-6, ηb, ω_o, ω_i, h)[1]) / 2e-6 rtol = 1e-5
end

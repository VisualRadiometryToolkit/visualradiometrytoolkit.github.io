@testitem "the parameter protocol of the vignetting fields and the light; restrict(ch, Z)" begin
    using Test
    import VisualRadiometryToolkitCore
    import VisualGeometryToolkitCore as VgtkCore
    using VisualRadiometryToolkitCore: TensorProductVignetting, RadialVignetting, LogVignetting, EnvironmentLight, SphericalHarmonicMap, control_points, coefficients, pole_regular_basis
    using VisualGeometryToolkitCore: parameter_vector, parameter_names, with_parameters, ParameterManifold, retract, recenter, retract_jacobian, local_coordinates, restrict, tangent_size, Rect2
    using StaticArrays: SVector
    using LinearAlgebra: Diagonal, qr
    v = TensorProductVignetting((5, 4), Rect2(0.0, 0.0, 100.0, 80.0))
    θ = parameter_vector(v)
    @test length(θ) == 20 && θ == vec(control_points(v)) && parameter_names(v)[[1, 20]] == (:c1, :c20)
    θ2 = θ .+ (1:20) ./ 100
    @test parameter_vector(with_parameters(v, θ2)) == θ2
    @test_throws ArgumentError with_parameters(v, θ[1:3])
    ch = ParameterManifold(v)
    @test tangent_size(ch) == 20 && parameter_vector(retract(ch, θ2 - θ)) == θ2
    @test local_coordinates(ch, with_parameters(v, θ2)) ≈ θ2 - θ
    lv = LogVignetting(v)
    @test parameter_vector(with_parameters(lv, θ2)) == θ2
    # a radial profile on its pole-regular subspace: vec(P) = vec(P₀) + Z y
    rv = RadialVignetting(6, SVector(50.0, 40.0), 60.0)
    Z = pole_regular_basis(rv)
    rch = restrict(ParameterManifold(rv), Z)
    y = SVector{size(Z, 2)}(range(0.1, 0.5; length = size(Z, 2)))
    @test tangent_size(rch) == size(Z, 2)
    @test parameter_vector(retract(rch, y)) ≈ parameter_vector(rv) + Z * y
    @test retract_jacobian(rch) ≈ Z
    @test local_coordinates(rch, retract(rch, y)) ≈ y
    @test parameter_vector(VgtkCore.model(recenter(rch, y))) ≈ parameter_vector(rv) + Z * y
    @test_throws ArgumentError restrict(ParameterManifold(rv), zeros(3, 2))
    @test_throws ArgumentError restrict(ParameterManifold(rv), hcat(Z[:, 1], Z[:, 1]))  # dependent columns
    # the cached factorization gives the normal-equation values, on a large basis too
    v_off = parameter_vector(rv) .+ (1:length(parameter_vector(rv))) ./ 50
    vfull = local_coordinates(ParameterManifold(rv), with_parameters(rv, v_off))
    @test local_coordinates(rch, with_parameters(rv, v_off)) ≈ (Z' * Z) \ (Z' * vfull)
    big = TensorProductVignetting((12, 12), Rect2(0.0, 0.0, 100.0, 80.0))
    Zb = Matrix(qr(reshape(sin.(1:144 * 30), 144, 30)).Q)[:, 1:30] .+ 0.01 .* reshape(cos.(1:144 * 30), 144, 30)
    tch = restrict(ParameterManifold(big), Zb)
    @test tch.basis isa Matrix{Float64} && tangent_size(tch) == 30
    yb = collect(range(-0.2, 0.3; length = 30))
    @test parameter_vector(retract(tch, yb)) ≈ parameter_vector(big) + Zb * yb
    @test local_coordinates(tch, retract(tch, yb)) ≈ yb
    θb = parameter_vector(big) .+ cos.(1:144)
    vb = local_coordinates(ParameterManifold(big), with_parameters(big, θb))
    @test local_coordinates(tch, with_parameters(big, θb)) ≈ (Zb' * Zb) \ (Zb' * vb)
    @test local_coordinates(recenter(tch, yb), retract(tch, yb)) ≈ zeros(30) atol = 1e-12
    # the light: its SH coefficients, column-major, centre and radius fixed
    L = EnvironmentLight(SphericalHarmonicMap(1.0, 1; channels = 2), SVector(0.0, 0.0, 0.0), 5.0)
    a = parameter_vector(L)
    @test length(a) == 8 && parameter_names(L)[1:3] == (:a1_1, :a2_1, :a1_2)
    L2 = with_parameters(L, a .+ 1)
    @test vec(coefficients(L2)) == a .+ 1 && L2.radius == 5.0
    @test local_coordinates(ParameterManifold(L), L2) ≈ ones(8)
end

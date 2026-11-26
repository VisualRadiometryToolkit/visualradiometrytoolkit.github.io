# The sensor domain (sensor/notation.jl) and the quadrature rules of the image-formation integrals (sensor/quadrature.jl). Moved
# with the code from RadiometricCamera's test/unit/quadrature_tests.jl.

@testitem "quadrature: the rules on a pixel and on the aperture; the sensor's pixels" begin
    using Test
    using VisualRadiometryToolkitCore: aperture_border, aperture_samples, sensor_samples, ApertureQuadrature, SensorQuadrature,
                                       pixel_position, pixel_footprint, sensor_position, sensor_sample, aperture_sample, aperture_weight,
                                       aperture_border_sample, n_disc, n_border, luma, luma_image
    import VisualRadiometryToolkitCore as VrtkCore
    using StaticArrays: SVector
    using LinearAlgebra: dot
    import VisualGeometryToolkitCore as VgtkCore

    sq = SensorQuadrature(3)
    @test sum(sq.weights) ≈ 1
    @test all(all(-0.5 .< o .< 0.5) for o in sq.offsets)
    aq = ApertureQuadrature(4, 12)
    @test sum(aq.w̃) ≈ π
    @test sum(w * a[1]^2 for (a, w) in zip(aq.â, aq.w̃)) ≈ π / 4 atol = 1e-12
    @test sum(w * (a[1]^2 + a[2]^2) for (a, w) in zip(aq.â, aq.w̃)) ≈ π / 2 atol = 1e-12
    @test n_disc(aq) == 48 && n_border(aq) == 12
    # aperture samples at radius r integrate the area πr²
    r = 0.03
    @test sum(w for (a, w) in aperture_samples(aq, r)) ≈ π * r^2
    @test first(aperture_samples(aq, r)) == (aperture_sample(aq, 1, r), aperture_weight(aq, 1, r)) && aperture_sample(aq, 1, r)[3] == 0
    @test sum(ds for (a, v, n, ds) in aperture_border(aq, r)) ≈ 2π * r
    @test all(abs(dot(v, n) - 1) < 1e-14 for (a, v, n, ds) in aperture_border(aq, r))
    @test first(aperture_border(aq, r)) == aperture_border_sample(aq, 1, r)
    @test sensor_position(3, 7) == SVector(2.5, 6.5) && pixel_position(sensor_position(3, 7)) ≈ SVector(3.0, 7.0)     # COLMAP pixels: pixel (u, v)'s centre
    @test sensor_position(SVector(3, 7)) == SVector(2.5, 6.5)
    lo, hi = pixel_footprint(1, 1); @test lo ≈ SVector(0.0, 0.0) && hi ≈ SVector(1.0, 1.0)
    # the sensor rule is the pixel box: the tensor Gauss–Legendre rule, its weights summing to one
    @test fieldnames(SensorQuadrature) == (:offsets, :weights) && sum(SensorQuadrature{Float64}(3).weights) ≈ 1
    @test all(o -> all(abs.(o) .< 0.5), SensorQuadrature{Float64}(3).offsets) && length(SensorQuadrature(4)) == 16
    @test all(((𝐩, w),) -> all(lo .< 𝐩 .< hi), sensor_samples(sq, 1, 1)) && first(sensor_samples(sq, 2, 5))[1] == sensor_sample(sq, 1, 2, 5)
    # the rules in a device kernel's float, verbatim; isbits
    s32 = VgtkCore.convert_eltype(Float32, sq); a32 = VgtkCore.convert_eltype(Float32, aq)
    @test s32 isa SensorQuadrature{Float32, 9} && s32.weights == Float32.(sq.weights) && a32 isa ApertureQuadrature{Float32, 48, 12} && a32.w̃ == Float32.(aq.w̃)
    @test isbits(sq) && isbits(aq) && sensor_sample(s32, 1, 2, 5) isa SVector{2, Float32}
    # Rec. 709 luma: of a triple, of an image's planes
    @test luma(SVector(1.0, 1.0, 1.0)) ≈ 1 && luma(SVector(0.0f0, 1.0f0, 0.0f0)) === 0.7152f0
    img = cat(fill(0.2, 2, 3), fill(0.4, 2, 3), fill(0.6, 2, 3); dims = 3)
    @test luma_image(img) ≈ fill(0.2126 * 0.2 + 0.7152 * 0.4 + 0.0722 * 0.6, 2, 3) && luma_image(img[:, :, 1:1]) == fill(0.2, 2, 3)
end

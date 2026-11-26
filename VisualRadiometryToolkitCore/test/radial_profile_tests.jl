@testitem "radial profile: a binned profile on the one chart registry (equisolid among it)" begin
    using Test, StaticArrays
    using VisualRadiometryToolkitCore
    using VisualGeometryToolkitCore
    using VisualRadiometryToolkitCore: BinnedRadialProfile, RADIAL_CHART_TAGS, LinearChart, ProjectiveChart, EquisolidChart, radial_chart, radial_coordinate, field_radius

    @test collect(keys(RADIAL_CHART_TAGS)) == ["linear", "projective", "equisolid"]
    edges = collect(range(0.0, 1.2; length = 7))
    vals = [1.0 0.95 0.9 0.8 0.7 0.5; 1.0 0.96 0.91 0.82 0.71 0.52]
    p = BinnedRadialProfile(EquisolidChart(), (1000.0, 750.0), 1200.0, edges, vals, [10, 20, 30, 40, 50, 60]; focal_length = 900.0)
    @test radial_chart(p) === EquisolidChart() && field_radius(p) == 1200.0 && VisualGeometryToolkitCore.center(p) == SVector(1000.0, 750.0)
    d = 450.0
    @test radial_coordinate(p, SVector(1000.0 + d, 750.0)) ≈ 2asin(d / 1800) rtol = 4eps()   # θ = 2 asin(d / 2f)
    @test searchsortedlast(p.edges, radial_coordinate(p, SVector(1000.0, 750.0))) == 1          # the centre: bin 1 (1-based)
    lin = BinnedRadialProfile(LinearChart(), (0.0, 0.0), 100.0, [0.0, 0.5, 1.0], [1.0 0.5], [3, 4])
    @test radial_coordinate(lin, SVector(30.0, 40.0)) == 0.5
    proj = BinnedRadialProfile(ProjectiveChart(), (0.0, 0.0), 100.0, [0.0, 0.5, 1.0], [1.0 0.5], [3, 4])
    @test radial_coordinate(proj, SVector(60.0, 80.0)) ≈ 0.5                                  # ½ at the radius
    @test p == BinnedRadialProfile(EquisolidChart(), (1000.0, 750.0), 1200.0, edges, vals, [10, 20, 30, 40, 50, 60]; focal_length = 900.0)
    @test hash(p) == hash(BinnedRadialProfile(EquisolidChart(), (1000.0, 750.0), 1200.0, edges, vals, [10, 20, 30, 40, 50, 60]; focal_length = 900.0))
    # the checks
    @test_throws ArgumentError BinnedRadialProfile(EquisolidChart(), (0.0, 0.0), 1.0, [0.0, 1.0], ones(1, 1), [1])           # no focal length
    @test_throws ArgumentError BinnedRadialProfile(LinearChart(), (0.0, 0.0), 1.0, [0.0, 1.0], ones(1, 1), [1]; focal_length = 2.0)
    @test_throws MethodError BinnedRadialProfile(:fisheye, (0.0, 0.0), 1.0, [0.0, 1.0], ones(1, 1), [1])
    @test_throws ArgumentError BinnedRadialProfile(LinearChart(), (0.0, 0.0), 1.0, [0.0, 0.0], ones(1, 1), [1])              # not increasing
    @test_throws DimensionMismatch BinnedRadialProfile(LinearChart(), (0.0, 0.0), 1.0, [0.0, 1.0, 2.0], ones(1, 1), [1, 1])
    @test_throws ArgumentError BinnedRadialProfile(LinearChart(), (0.0, 0.0), 1.0, [0.0, 1.0], ones(1, 1), [-1])
    @test_throws DimensionError BinnedRadialProfile(LinearChart(), (0.0, 0.0), 1.0mm, [0.0, 1.0], ones(1, 1), [1])           # pixels, not a length
    # a fitted profile is on a normalized radius: equisolid is refused there
    @test_throws ArgumentError RadialVignetting(6, (0.0, 0.0), 100.0; chart = EquisolidChart())
end

# The physical forms of the radiometric layer: a board posed in the world, the light about it, a light's terms by (l, m), a field
# fitted to a function, and a camera's lengths.

@testitem "physical forms: a bare board posed in the world, oriented by its cameras" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, with_facing, board_normal, corners, world_point
    import VisualRadiometryToolkitCore as VrtkCore
    import VisualGeometryToolkitCore as VgtkCore
    using VisualGeometryToolkitCore: Board, PlanarTarget, PosedTarget, EuclideanMap, Size2, m, centroid
    using StaticArrays: SVector
    using LinearAlgebra: I

    tex = fill(0.5, 8, 8, 3)
    pose = EuclideanMap(VgtkCore.Rotations.RotMatrix{3, Float64}(I), [0.0m, 0.0m, 0.0m])
    target = PosedTarget(PlanarTarget(SVector{2, Float64}[]; board = Board(Size2(width = 2m, height = 2m), [-1m, -1m])), pose)
    b = TexturedTarget(target, tex)                                         # a board, no canvas: the texture covers the board
    @test b.size ≈ SVector(2.0, 2.0) && centroid(b) ≈ SVector(0.0, 0.0, 0.0)
    @test collect(corners(b)) ≈ [SVector(-1.0, 1.0, 0.0), SVector(1.0, 1.0, 0.0), SVector(1.0, -1.0, 0.0), SVector(-1.0, -1.0, 0.0)]
    @test board_normal(b) ≈ SVector(0.0, 0.0, 1.0)                          # the design's +z, the printed side, until oriented
    @test board_normal(with_facing(b, SVector(0.3, 0.1, 1.5))) ≈ SVector(0.0, 0.0, 1.0)
    @test board_normal(with_facing(b, SVector(0.0, 0.0, -1.5))) ≈ SVector(0.0, 0.0, -1.0)
    @test with_facing(b, SVector(0.0, 0.0, 1.5)).texture === b.texture
    # the board's own type, inferred: concretely for a concrete board, and as a `TexturedTarget` (never `Any`) for a board whose
    # type the caller's inference holds only in part (a session's, RadiometricCamera's `load_session`)
    @test @inferred(with_facing(b, SVector(0.0, 0.0, 1.5))) isa typeof(b)
    @test @inferred(with_facing(b, [0.0, 0.0, 1.5])) isa typeof(b)
    @test only(Base.return_types(with_facing, (TexturedTarget, SVector{3, Float64}))) <: TexturedTarget
    @test only(Base.return_types(with_facing, (TexturedTarget{Float64}, SVector{3, Float64}))) <: TexturedTarget{Float64}
    # the edge-vector form of the same page agrees with the posed form, once both face the same camera
    e = TexturedTarget(SVector(-1.0, 1.0, 0.0), SVector(2.0, 0.0, 0.0), SVector(0.0, -2.0, 0.0), tex)
    @test world_point(e, SVector(0.2, 0.7)) ≈ world_point(b, SVector(0.2, 0.7))
    # a target with neither a canvas nor a board is refused by name
    @test_throws ArgumentError TexturedTarget(PosedTarget(PlanarTarget(SVector{2, Float64}[]), pose), tex)
end

@testitem "physical forms: the light about the board, its terms by (l, m)" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, EnvironmentLight, SphericalHarmonicMap, coefficients, sh_index, corners
    using VisualGeometryToolkitCore: lookat_pose, Vec3, centroid
    using StaticArrays: SVector
    using LinearAlgebra: norm

    sky = SphericalHarmonicMap(2, (0, 0) => (2.0, 1.9, 1.8), (1, 0) => (0.4, 0.3, 0.2))
    a = zeros(3, 9); a[:, 1] .= (2.0, 1.9, 1.8); a[:, 3] .= (0.4, 0.3, 0.2)
    @test coefficients(sky) == SphericalHarmonicMap(a, 2).coefficients          # the pair form is the matrix form's columns
    @test coefficients(sky, 1, 0) == SVector(0.4, 0.3, 0.2) && sh_index(1, 0) == 3 && iszero(coefficients(sky, 2, -1))
    @test_throws ArgumentError SphericalHarmonicMap(2, (3, 0) => (1.0, 1.0, 1.0))
    @test_throws ArgumentError SphericalHarmonicMap(2, (1, 0) => (1.0, 1.0, 1.0), (1, 0) => (2.0, 2.0, 2.0))
    @test_throws DimensionMismatch SphericalHarmonicMap(2, (0, 0) => (1.0, 1.0, 1.0), (1, 0) => (1.0,))
    @test_throws ArgumentError coefficients(sky, 1, 2)

    b = TexturedTarget(SVector(-1.0, 1.0, 0.0), SVector(2.0, 0.0, 0.0), SVector(0.0, -2.0, 0.0), fill(0.5, 4, 4, 3))
    near = [lookat_pose(Vec3(0.1, 0.0, 0.6), Vec3(0.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0))]          # closer than the page's corners
    far = [lookat_pose(Vec3(0.3, 0.2, 2.5), Vec3(0.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0))]
    @test EnvironmentLight(sky, b, near).radius ≈ sqrt(2.0)                    # the corners hold it
    @test EnvironmentLight(sky, b, far).radius ≈ norm(SVector(0.3, 0.2, 2.5))  # the camera holds it
    @test EnvironmentLight(sky, b, far).center == centroid(b) && coefficients(EnvironmentLight(sky, b, far), 1, 0) == coefficients(sky, 1, 0)
end

@testitem "physical forms: a field fitted to a function, a radial profile about the camera" begin
    using Test
    using VisualRadiometryToolkitCore: RadialVignetting, TensorProductVignetting, LogVignetting, control_points, field_radius,
                                       ProjectiveChart
    using VisualRadiometryToolkitCore: VignettingLeastSquares
    using VisualGeometryToolkitCore: imaged_region
    using LinearAlgebra: norm
    using VisualGeometryToolkitCore: BoundedCamera, CameraModel, CameraCalibrationMat, Lens, DoubleSphere, Size2, Rect,
                                     EstimationProblem, ClosedFormKind, estimator_kind, solve
    import VisualGeometryToolkitCore as VgtkCore
    using StaticArrays: SVector
    least_squares(f, field, camera; kw...) = solve(EstimationProblem(typeof(field), (f, field, camera)), VignettingLeastSquares(; kw...))

    K = CameraCalibrationMat(412.0, 0.0, 0.0, 0.0, 412.0, 0.0, 150.0, 110.0, 1.0)
    g = BoundedCamera(CameraModel(K; lens = Lens(DoubleSphere(0.25, 0.4))), Size2(320, 240))
    v = RadialVignetting(6, g)
    @test v.center == SVector(150.0, 110.0) && field_radius(v) ≈ hypot(170.0, 130.0)   # the principal point; the farthest corner
    @test all(==(1.0), control_points(v))                                     # flat
    # a function the field holds exactly is recovered exactly, on either kind of field
    c = SVector(150.0, 110.0)
    quad(𝐩) = 1 - 0.3 * (norm(𝐩 - c) / 214)^2                                 # radial, quadratic in the distance
    rr = least_squares(quad, RadialVignetting(6, g; degree = 2), g)
    @test VgtkCore.successful_retcode(rr) && rr.n == 33^2 && isnan(rr.rms) && rr.alg == VignettingLeastSquares()
    @test estimator_kind(VignettingLeastSquares()) === ClosedFormKind()
    r = rr.u
    @test maximum(abs(r(𝐩) - quad(𝐩)) for 𝐩 in (SVector(x, y) for x in 0.0:10.0:320.0, y in 0.0:10.0:240.0)) < 1e-8   # measured 2.6e-9 (a 2-D least squares; the 1-D radial fit's old check was 1e-10)
    t = TensorProductVignetting((4, 4), Rect(0, 0, 320, 240); degree = 2)
    plane(𝐩) = 0.9 + 1.0e-4 * 𝐩[1] - 2.0e-4 * 𝐩[2]
    rt = least_squares(plane, t, g).u
    @test least_squares(plane, t, g; samples = 9).n == 81
    @test rt(SVector(37.0, 201.0)) ≈ plane(SVector(37.0, 201.0))
    @test all(≈(1.0), control_points(least_squares(_ -> 1.0, t, g).u))
    # the samples are the imaged region's: none off the sensor (a radial field reaches the farthest corner's radius, past
    # the sensor along +x) and none outside the lens coverage
    for camera in (g, BoundedCamera(CameraModel(K; lens = Lens(DoubleSphere(0.25, 0.4))), Size2(320, 240);
                                    lens_coverage = VgtkCore.Circle(VgtkCore.Point2(150.0, 110.0), 120.0)))
        seen = SVector{2, Float64}[]
        record(𝐩) = (push!(seen, 𝐩); quad(𝐩))
        res = least_squares(record, RadialVignetting(6, camera; degree = 2), camera)
        @test res.n == length(seen) && !isempty(seen)
        @test all(𝐩 -> 𝐩 ∈ imaged_region(camera) && 0 <= 𝐩[1] <= 320 && 0 <= 𝐩[2] <= 240, seen)
    end
    let camera = BoundedCamera(CameraModel(K; lens = Lens(DoubleSphere(0.25, 0.4))), Size2(320, 240);
                               lens_coverage = VgtkCore.Circle(VgtkCore.Point2(150.0, 110.0), 120.0))
        @test least_squares(quad, RadialVignetting(6, camera; degree = 2), camera).n < 33^2   # the circle's samples only
    end
    # refused: a radial field on the projective chart (by name), a log field, too few samples
    err = try least_squares(quad, RadialVignetting(8, g; chart = ProjectiveChart()), g); nothing catch e; e end
    @test err isa ArgumentError && occursin("ProjectiveChart", err.msg)
    @test_throws ArgumentError least_squares(plane, LogVignetting(t), g)
    @test_throws ArgumentError least_squares(plane, t, g; samples = 2)   # 4 samples cannot determine 16 control points
end

@testitem "physical forms: a camera's lengths" begin
    using Test
    using VisualRadiometryToolkitCore: RadiometricCameraModel, Focus, focus, aperture_radius, focus_distance
    using VisualGeometryToolkitCore: BoundedCamera, CameraModel, CameraCalibrationMat, Lens, DoubleSphere, Size2, Sensor, m, mm, cm, μm, px
    using StaticArrays: SVector

    K = CameraCalibrationMat(412.0, 0.0, 0.0, 0.0, 412.0, 0.0, 160.0, 120.0, 1.0)
    g = BoundedCamera(CameraModel(K; lens = Lens(DoubleSphere(0.25, 0.4))), Size2(320, 240))
    c = RadiometricCameraModel(g; focus = 1.5m, aperture_radius = 2mm)
    @test aperture_radius(c) ≈ 0.002 && focus_distance(focus(c), SVector(10.0, 10.0)) ≈ 1.5
    plain = RadiometricCameraModel(g; focus = 1.5, aperture_radius = 0.002)   # plain metres: as given
    @test aperture_radius(plain) === 0.002 && focus(plain).t̂_i ≈ focus(c).t̂_i
    @test aperture_radius(RadiometricCameraModel(g; focus = 150cm, aperture_radius = 0.2cm)) ≈ 0.002
    @test Focus(g, 1.5m).t̂_i ≈ Focus(g, 1.5).t̂_i
    @test_throws Exception RadiometricCameraModel(g; focus = 1.5m, aperture_radius = 2.0px)
    # the photographer's stop: an 8 mm lens on a sensor of 20 μm pixels at f/2 has an aperture radius of 2 mm
    sensor = Sensor(Size2(320, 240), 20μm)
    lens_on_sensor = BoundedCamera(8mm, sensor; lens = Lens(DoubleSphere(0.25, 0.4)))
    @test aperture_radius(RadiometricCameraModel(lens_on_sensor; focus = 1.5m, f_number = 2)) ≈ 0.002
    @test_throws ArgumentError RadiometricCameraModel(lens_on_sensor; focus = 1.5m)                                  # no aperture
    @test_throws ArgumentError RadiometricCameraModel(lens_on_sensor; focus = 1.5m, f_number = 2, aperture_radius = 2mm)   # two
    @test_throws ArgumentError RadiometricCameraModel(g; focus = 1.5m, f_number = 2)                                 # no pitch
end

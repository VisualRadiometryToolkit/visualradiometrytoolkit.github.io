# The focus surface (camera/focus.jl) and its kinds on the chief directions (camera/focus_charts.jl). Moved with the code from
# RadiometricCamera's test/unit/focus_tests.jl and focus_charts_tests.jl.

@testitem "focus: the thin plate spline of the inverse focus distance" begin
    using Test
    using VisualRadiometryToolkitCore: Focus, FocusSpline, n_nodes, inverse_focus_distance, focus_distance, t̂, 𝔱
    using StaticArrays: SVector
    import ForwardDiff
    import VisualGeometryToolkitCore as VgtkCore

    # the focus surface is VisualGeometryToolkitCore's thin-plate spline (its interpolation and bending energy are tested there): the
    # Focus of affine nodal values is that affine function, and of any values interpolates them
    W, H = 400, 300                                                  # the sensor [0, W] × [0, H] (pixels)
    tps = FocusSpline(VgtkCore.grid_nodes(5, VgtkCore.Rect(0, 0, W, H)))
    @test tps.nodes[1] == SVector(0.0, 0.0) && tps.nodes[25] == SVector(400.0, 300.0)
    vals = [0.3 + 1e-3 * n[1] - 2e-3 * n[2] for n in tps.nodes]
    fa = Focus(tps, vals)
    @test maximum(abs, fa.w) < 1e-9
    @test inverse_focus_distance(fa, SVector(244.0, 30.0)) ≈ 0.3 + 0.244 - 0.06 atol = 1e-10
    vals2 = rand(25)
    @test maximum(abs(inverse_focus_distance(Focus(tps, vals2), tps.nodes[i]) - vals2[i]) for i in 1:25) < 1e-9
    f = Focus(5, 1.5, W, H)
    @test t̂ === inverse_focus_distance && 𝔱 === focus_distance                       # the paper's notation: public aliases, the same functions
    @test focus_distance(f, SVector(280.0, 240.0)) ≈ 1.5 && inverse_focus_distance(f, SVector(40.0, 180.0)) ≈ 1 / 1.5
    fd = Focus(tps, ForwardDiff.Dual.(vals2, 1.0))
    @test inverse_focus_distance(fd, SVector(240.0, 180.0)) isa ForwardDiff.Dual
    @test n_nodes(f) == 25 && values(f) === f.t̂_i && isbits(f)

    # the parameter protocol: the nodal values, rebuilt through the host-side system; the element type converted verbatim
    @test VgtkCore.parameter_vector(fa) === fa.t̂_i && VgtkCore.parameter_names(fa)[25] === :t̂25
    f2 = VgtkCore.with_parameters(fa, vals2)
    @test f2.t̂_i == vals2 && f2.nodes == fa.nodes
    @test inverse_focus_distance(f2, tps.nodes[7]) ≈ vals2[7] atol = 1e-9
    ch = VgtkCore.ParameterManifold(fa)                                 # the chart an estimator steps the nodal values in
    @test VgtkCore.local_coordinates(ch, VgtkCore.retract(ch, 0.01 .* vals2)) ≈ 0.01 .* vals2
    f32 = VgtkCore.convert_eltype(Float32, fa)
    @test f32 isa Focus{Float32, 25} && f32.kind == fa.kind && f32.w == Float32.(fa.w) && inverse_focus_distance(f32, SVector(244.0f0, 30.0f0)) isa Float32
end

# EXPERIMENT (focus-ab): the direction-chart and spherical focus surfaces (src/camera/focus_charts.jl).
@testitem "focus charts (focus-ab experiment)" setup = [PixelCameras] begin
    using Test
    using VisualRadiometryToolkitCore: Focus, FocusSpline, inverse_focus_distance, focus_weights, polar_cap_nodes, chief_direction,
                                       FOCUS_SENSOR, FOCUS_DIRECTION_CHART, FOCUS_SPHERE
    using StaticArrays: SVector, SMatrix
    using LinearAlgebra: dot, norm, eigvals, Symmetric
    import ForwardDiff
    import VisualGeometryToolkitCore as VgtkCore

    mean(x) = sum(x) / length(x)
    equidistant = VgtkCore.Lens(VgtkCore.Equidistant())
    ae_chart(d) = SVector{2}(VgtkCore.project(equidistant, d)); ae_dir(ξ) = SVector{3}(VgtkCore.backproject(equidistant, ξ))   # the direct calls of the focus code
    @test (FOCUS_SENSOR, FOCUS_DIRECTION_CHART, FOCUS_SPHERE) == (0, 1, 2)
    # (Li₂, Wahba's kernel and the azimuthal-equidistant chart are VisualGeometryToolkitCore's: dilog, spherical_spline_kernel, the
    # equidistant lens — their accuracy is tested there)
    @testset "systems interpolate and weights are exact" begin
        nodes = polar_cap_nodes(25, 1.4)
        @test length(nodes) == 25
        @test ae_chart(ae_dir(nodes[7])) ≈ nodes[7] && norm(ae_dir(nodes[7])) ≈ 1
        # the chart IS VisualGeometryToolkitCore's equidistant lens, called directly (this package has no chart function): on a sample,
        # value for value (==, no tolerance) the lens's maps are its `equidistant_chart(ẑ)`'s, inverse included (Float64: the chart's
        # rotation about ẑ is the identity), and the Float32 path stays Float32
        chart = VgtkCore.equidistant_chart(SVector(0.0, 0.0, 1.0))
        for ξ in nodes
            d = ae_dir(ξ)
            @test d == inv(chart.f2)(VgtkCore.backproject(chart.f1, ξ)) && ae_chart(d) == chart(d) && all(isfinite, d)   # chart = lens ∘ rotation (CoordinateTransformations' f1 ∘ f2)
            ξ32 = SVector{2, Float32}(ξ); d32 = ae_dir(ξ32)
            @test d32 isa SVector{3, Float32} && ae_chart(d32) isa SVector{2, Float32}
            @test d32 ≈ d rtol = 1.0f-6
            @test ae_chart(d32) ≈ ξ32 atol = 1.0f-5
        end
        lens = cam(VgtkCore.KannalaBrandt(-0.04, 0.003, -0.004, 0.002), 72.0, (200.0, 150.0), 400, 300; f_y = 81.0)   # f_x, f_y, c (pixels), k₁…k₄
        for kind in (1, 2)
            tps = FocusSpline(nodes, kind)
            t = [0.5 + 0.3 * sin(3 * n[1]) * cos(2 * n[2]) for n in nodes]
            f = Focus(tps, t)
            @test f.kind == kind
            for (i, ξ) in enumerate(nodes)
                @test inverse_focus_distance(f, ae_dir(ξ)) ≈ t[i] atol = 1e-10
            end
            𝐩 = SVector(252.0, 126.0)
            g = focus_weights(tps, lens, 𝐩)
            d = chief_direction(lens, 𝐩)
            @test dot(g, t) ≈ inverse_focus_distance(f, d) atol = 1e-12
            @test inverse_focus_distance(lens, f, 𝐩) == inverse_focus_distance(f, d)                                        # the camera's t̂ of a direction kind: at the chief direction
            @test sum(g) ≈ 1 atol = 1e-10                                              # constants reproduced
            fd = ForwardDiff.gradient(tt -> inverse_focus_distance(Focus(tps, tt), d), t)
            @test fd ≈ g atol = 1e-10
            @test FocusSpline(f).kind == kind
            # a smoothness's rows: the bending rows of the chart's system over m̄ — ‖L t‖² is the bending energy over the mean positive
            # eigenvalue of Q
            L = VgtkCore.bending_rows(tps.sys) ./ sqrt(VgtkCore.mean_positive_eigenvalue(VgtkCore.bending_rows(tps.sys)))
            λ = eigvals(Symmetric(tps.sys.Q)); λp = λ[λ .> 1e-10 * maximum(λ)]
            @test sum(abs2, L * t) ≈ VgtkCore.bending_energy(tps.sys, t) / mean(λp) rtol = 1e-8
            @test norm(L * ones(25)) < 1e-6 * norm(L)                                  # constants carry no bending
        end
    end
    @testset "kind 0 unchanged" begin
        tps = FocusSpline(VgtkCore.grid_nodes(5, VgtkCore.Rect(0, 0, 400, 300)))
        f = Focus(tps, collect(range(0.1, 2.0; length = 25)))
        @test f.kind == 0 && tps.kind == 0
        lens = cam(VgtkCore.KannalaBrandt(-0.04, 0.003, -0.004, 0.002), 72.0, (200.0, 150.0), 400, 300; f_y = 81.0)
        @test focus_weights(tps, lens, SVector(240.0, 210.0)) == VgtkCore.nodal_weights(tps.sys, SVector(240.0, 210.0))
        c = RadiometricCameraModel(lens, f, 1e-3, TensorProductVignetting((4, 4), VgtkCore.Rect(0, 0, 400, 300); degree = 2))
        @test inverse_focus_distance(c, SVector(240.0, 210.0)) === inverse_focus_distance(f, SVector(240.0, 210.0))
    end
end

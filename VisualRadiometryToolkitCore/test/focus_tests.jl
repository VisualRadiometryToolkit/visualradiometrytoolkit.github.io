# The focus surface (camera/focus.jl) and its kinds on the chief directions (camera/focus_charts.jl). Moved with the code from
# RadiometricCamera's test/unit/focus_tests.jl and focus_charts_tests.jl.

@testitem "focus: the thin plate spline of the inverse focus distance" begin
    using Test
    using VisualRadiometryToolkitCore: Focus, FocusSpline, n_nodes, t̂, 𝔱
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
    @test t̂(fa, SVector(244.0, 30.0)) ≈ 0.3 + 0.244 - 0.06 atol = 1e-10
    vals2 = rand(25)
    @test maximum(abs(t̂(Focus(tps, vals2), tps.nodes[i]) - vals2[i]) for i in 1:25) < 1e-9
    f = Focus(5, 1.5, W, H)
    @test 𝔱(f, SVector(280.0, 240.0)) ≈ 1.5 && t̂(f, SVector(40.0, 180.0)) ≈ 1 / 1.5
    fd = Focus(tps, ForwardDiff.Dual.(vals2, 1.0))
    @test t̂(fd, SVector(240.0, 180.0)) isa ForwardDiff.Dual
    @test n_nodes(f) == 25 && values(f) === f.t̂_i && isbits(f)

    # the parameter protocol: the nodal values, rebuilt through the host-side system; the element type converted verbatim
    @test VgtkCore.parameter_vector(fa) === fa.t̂_i && VgtkCore.parameter_names(fa)[25] === :t̂25
    f2 = VgtkCore.with_parameters(fa, vals2)
    @test f2.t̂_i == vals2 && f2.nodes == fa.nodes
    @test t̂(f2, tps.nodes[7]) ≈ vals2[7] atol = 1e-9
    f32 = VgtkCore.convert_eltype(Float32, fa)
    @test f32 isa Focus{Float32, 25} && f32.kind == fa.kind && f32.w == Float32.(fa.w) && t̂(f32, SVector(244.0f0, 30.0f0)) isa Float32
end

# EXPERIMENT (focus-ab): the direction-chart and spherical focus surfaces (src/camera/focus_charts.jl).
@testitem "focus charts (focus-ab experiment)" setup = [PixelCameras] begin
    using Test
    using VisualRadiometryToolkitCore: Focus, FocusSpline, t̂, t̂_dir, ae_dir, ae_chart, focus_weights, polar_cap_nodes, chief_dir,
                                       FOCUS_SENSOR, FOCUS_DIRECTION_CHART, FOCUS_SPHERE
    using StaticArrays: SVector, SMatrix
    using LinearAlgebra: dot, norm, eigvals, Symmetric
    import ForwardDiff
    import VisualGeometryToolkitCore as VgtkCore

    mean(x) = sum(x) / length(x)
    @test (FOCUS_SENSOR, FOCUS_DIRECTION_CHART, FOCUS_SPHERE) == (0, 1, 2)
    # (Li₂, Wahba's kernel and the azimuthal-equidistant chart are VisualGeometryToolkitCore's: dilog, spherical_spline_kernel, the
    # equidistant lens — their accuracy is tested there)
    @testset "systems interpolate and weights are exact" begin
        nodes = polar_cap_nodes(25, 1.4)
        @test length(nodes) == 25
        @test ae_chart(ae_dir(nodes[7])) ≈ nodes[7] && norm(ae_dir(nodes[7])) ≈ 1
        lens = cam(VgtkCore.KannalaBrandt(-0.04, 0.003, -0.004, 0.002), 72.0, (200.0, 150.0), 400, 300; f_y = 81.0)   # f_x, f_y, c (pixels), k₁…k₄
        for kind in (1, 2)
            tps = FocusSpline(nodes, kind)
            t = [0.5 + 0.3 * sin(3 * n[1]) * cos(2 * n[2]) for n in nodes]
            f = Focus(tps, t)
            @test f.kind == kind
            for (i, ξ) in enumerate(nodes)
                @test t̂_dir(f, ae_dir(ξ)) ≈ t[i] atol = 1e-10
            end
            𝐩 = SVector(252.0, 126.0)
            g = focus_weights(tps, lens, 𝐩)
            d = chief_dir(lens, 𝐩)
            @test dot(g, t) ≈ t̂_dir(f, d) atol = 1e-12
            @test t̂(lens, f, 𝐩) == t̂_dir(f, d)                                        # the camera's t̂ of a direction kind: at the chief direction
            @test sum(g) ≈ 1 atol = 1e-10                                              # constants reproduced
            fd = ForwardDiff.gradient(tt -> t̂_dir(Focus(tps, tt), d), t)
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
        @test t̂(c, SVector(240.0, 210.0)) === t̂(f, SVector(240.0, 210.0))
    end
end

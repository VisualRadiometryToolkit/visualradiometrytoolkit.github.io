# The focus surface (camera/focus.jl). Moved with the code from RadiometricCamera's test/unit/focus_tests.jl.

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
    @test f32 isa Focus{Float32, 25} && f32.w == Float32.(fa.w) && inverse_focus_distance(f32, SVector(244.0f0, 30.0f0)) isa Float32
    @test fieldnames(Focus) == (:nodes, :t̂_i, :w, :a) && fieldnames(FocusSpline) == (:sys, :nodes, :coeff)
    @test tps.sys isa VgtkCore.ThinPlateSplineSystem && tps.coeff === tps.sys.coeff && FocusSpline(fa).nodes == tps.nodes

    # a camera's inverse focus distance at 𝐩 is the surface's thin plate spline at 𝐩, whatever its geometric camera
    @test inverse_focus_distance(nothing, fa, SVector(244.0, 30.0)) === inverse_focus_distance(fa, SVector(244.0, 30.0))

    # the focus surfaces on the chief directions were removed: their call forms and names are refused by name
    message(f) = try f(); "" catch e; e isa ArgumentError ? e.msg : rethrow() end
    for m in (message(() -> FocusSpline(tps.nodes, 1)), message(() -> FocusSpline(tps.nodes, 0)),
              message(() -> inverse_focus_distance(fa, SVector(0.0, 0.0, 1.0))),
              message(() -> VisualRadiometryToolkitCore.focus_weights(tps, nothing, SVector(1.0, 2.0))),
              message(() -> VisualRadiometryToolkitCore.polar_cap_nodes(25, 1.4)))
        @test occursin("was removed", m) && occursin("the thin plate spline over the sensor", m)
    end
    @test !any(n -> isdefined(VisualRadiometryToolkitCore, n), (:FOCUS_SENSOR, :FOCUS_DIRECTION_CHART, :FOCUS_SPHERE))
end

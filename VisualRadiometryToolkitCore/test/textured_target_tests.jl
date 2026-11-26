# The textured target: VisualGeometryToolkitCore's posed planar target with its texture, its printed edge and its own state.

@testitem "textured target: the page, its chart, its albedo" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, TargetState, posed_target, board_normal, world_point, with_facing, corners,
                                       texture_size, intersect_board, board_plane_hit, inside, albedo, printed_albedo, has_sdf
    import VisualRadiometryToolkitCore as VrtkCore
    import VisualGeometryToolkitCore as VgtkCore
    using StaticArrays: SVector
    using LinearAlgebra: norm, dot, cross

    tex = zeros(4, 6, 3); tex[:, 1:3, :] .= 0.2; tex[:, 4:6, :] .= 0.8
    𝐨 = SVector(-0.3, -0.2, 1.0); 𝐮 = SVector(0.6, 0.0, 0.0); 𝐯 = SVector(0.0, 0.4, 0.0)
    b = with_facing(TexturedTarget(𝐨, 𝐮, 𝐯, tex), SVector(0.0, 0.0, 0.0))
    @test b.state === TargetState{Float64}() && isbits(b.state) && !has_sdf(b)
    @test texture_size(b) == (4, 6) && b.size == SVector(0.6, 0.4)
    # the geometry is VisualGeometryToolkitCore's posed planar target; the flat target as designed is its own posed target
    @test posed_target(b) === b.target && b.target isa VgtkCore.PosedTarget
    @test world_point(b, SVector(0.0, 0.0)) ≈ 𝐨 && world_point(b, SVector(1.0, 1.0)) ≈ 𝐨 + 𝐮 + 𝐯
    @test collect(corners(b)) ≈ [𝐨, 𝐨 + 𝐮, 𝐨 + 𝐮 + 𝐯, 𝐨 + 𝐯]
    @test VgtkCore.centroid(b) ≈ 𝐨 + 𝐮 / 2 + 𝐯 / 2
    @test VrtkCore.𝔟 === VgtkCore.centroid && VrtkCore.ρ_c === albedo         # the paper's notation: public aliases, the same functions
    @test board_normal(with_facing(b, SVector(0.0, 0.0, 2.0))) ≈ SVector(0.0, 0.0, 1.0)   # oriented by a viewpoint on the other side
    @test board_normal(b) ≈ SVector(0.0, 0.0, -1.0)                           # towards the camera at the origin
    𝐛 = SVector(0.3, 0.7)
    @test VgtkCore.chart(b, world_point(b, 𝐛)) ≈ 𝐛
    # a ray from the origin to a page point meets the page there; one off the page misses; the plane hit lands wherever
    x = world_point(b, 𝐛); d = x / norm(x)
    s, hit = intersect_board(b, SVector(0.0, 0.0, 0.0), d)
    @test s ≈ norm(x) && hit ≈ x
    off = 𝐨 - 𝐮; doff = off / norm(off)
    @test isnan(first(intersect_board(b, SVector(0.0, 0.0, 0.0), doff)))
    sp, xp = board_plane_hit(b, SVector(0.0, 0.0, 0.0), doff)
    @test sp ≈ norm(off) && xp ≈ off
    @test inside(𝐛) && !inside(SVector(1.2, 0.5)) && !inside(SVector(0.01, 0.5), 0.02)
    # the albedo: the texture, bilinear on texel centres
    @test albedo(b, SVector(0.1, 0.5)) ≈ SVector(0.2, 0.2, 0.2) && albedo(b, SVector(0.9, 0.5)) ≈ SVector(0.8, 0.8, 0.8)
    @test albedo(b, SVector(0.5, 0.5)) ≈ SVector(0.5, 0.5, 0.5)
    @test printed_albedo(b, SVector(0.9, 0.5)) === albedo(b, SVector(0.9, 0.5))   # no distance map: the texture's
    # Float32, element types only; the posed target (host) is kept
    b32 = VgtkCore.convert_eltype(Float32, b)
    @test b32 isa TexturedTarget{Float32} && b32.state === TargetState{Float32}() && b32.target === b.target
    @test albedo(b32, SVector(0.9f0, 0.5f0)) isa SVector{3, Float32}
    @test_throws ArgumentError TexturedTarget(𝐨, 𝐮, 𝐯 + 𝐮, tex)                 # the page's edges are orthogonal
end

@testitem "textured target: its own state, by value" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, TargetState, with_facing, with_state, with_h, with_edge, with_inplane, height_on, inplane_on,
                                       ink_spread, print_blur, EDGE_NC, HEIGHT_NC, HEIGHT_NODES, INPLANE_NC, with_sdf, has_sdf,
                                       edge_albedo, printed_albedo, albedo
    import VisualGeometryToolkitCore as VgtkCore
    import ForwardDiff
    using Adapt: adapt
    using StaticArrays: SVector

    @test (EDGE_NC, HEIGHT_NC, INPLANE_NC) == (2, 25, 2) && length(HEIGHT_NODES) == HEIGHT_NC
    s = TargetState()
    @test s === TargetState{Float64}() && isbits(s) && !height_on(s) && !inplane_on(s)
    h = SVector{HEIGHT_NC}(1.0e-3 .* (1:HEIGHT_NC))
    s1 = with_inplane(with_edge(with_h(s, h), (0.05, 0.02)), (1.0e-3, -2.0e-3))
    @test s1.h == h && s1.edge == SVector(0.05, 0.02) && s1.inplane == SVector(1.0e-3, -2.0e-3)
    @test height_on(s1) && inplane_on(s1) && ink_spread(s1) == 0.05 && print_blur(s1) == 0.02
    @test TargetState(; h, edge = (0.05, 0.02), inplane = (1.0e-3, -2.0e-3)) === s1
    @test VgtkCore.convert_eltype(Float32, s1) isa TargetState{Float32}

    tex = fill(0.5, 4, 6, 3)
    b = with_facing(TexturedTarget(SVector(-0.3, -0.2, 1.0), SVector(0.6, 0.0, 0.0), SVector(0.0, 0.4, 0.0), tex), SVector(0.0, 0.0, 0.0))
    # the state is replaced by value: the same arrays (no copy), the state in its own element type
    b1 = with_state(b, s1)
    @test b1.state === s1 && b1.texture === b.texture && b1.quad === b.quad && b1.warping === b.warping
    @test with_h(b, h).state === with_h(b.state, h) && with_edge(b, (0.05, 0.02)).state.edge == SVector(0.05, 0.02) &&
          with_inplane(b, (1.0e-3, -2.0e-3)).state.inplane == SVector(1.0e-3, -2.0e-3)
    @test height_on(b1) && inplane_on(b1) && !height_on(b) && ink_spread(b1) == 0.05 && print_blur(b1) == 0.02
    D = ForwardDiff.Dual{Nothing, Float64, 1}
    bd = with_state(b, TargetState{D}(D.(h), D.(s1.edge), D.(s1.inplane)))
    @test bd.state isa TargetState{D} && bd.texture === b.texture && eltype(bd.texture) == Float64
    # on a device the posed target stays behind; the state travels with the target
    a = adapt(Array, b1)
    @test a.target === nothing && a.state === s1 && a.texture == b1.texture

    # the printed edge: a vertical ink edge at the page's middle (signed distance, mm, + on paper)
    sdf = [0.3 * (u - 3.5) for v in 1:4, u in 1:6]                          # paper to the right of the middle column boundary
    e = with_edge(with_sdf(b, sdf, (600.0, 400.0)), (0.0, 0.1))
    @test has_sdf(e) && e.state.edge == SVector(0.0, 0.1)
    ρ(𝐛) = edge_albedo(e, 𝐛)[1]
    @test ρ(SVector(0.5, 0.5)) ≈ 0.5 atol = 1.0e-6                           # on the edge: half ink
    @test ρ(SVector(0.9, 0.5)) > 0.99 && ρ(SVector(0.1, 0.5)) < 0.01        # paper, ink
    @test printed_albedo(e, SVector(0.9, 0.5)) === edge_albedo(e, SVector(0.9, 0.5)) != albedo(e, SVector(0.9, 0.5))
    # an ink spread δ moves the edge towards the paper: less albedo at the same point
    @test edge_albedo(with_edge(e, (0.05, 0.1)), SVector(0.5, 0.5))[1] < 0.5
    # the derivative in the ink spread flows through the state
    g = ForwardDiff.derivative(δ -> edge_albedo(with_state(e, TargetState(; edge = SVector(δ, 0.1 * one(δ)))), SVector(0.5, 0.5))[1], 0.0)
    @test g < 0
    @test_throws ArgumentError TexturedTarget(SVector(0.0, 0.0, 1.0), SVector(0.6, 0.0, 0.0), SVector(0.0, 0.4, 0.0), tex; sdf)   # a map needs its size
end

@testitem "textured target: the warped page and the in-plane print error" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, TargetState, with_facing, with_state, with_h, HEIGHT_NC, HEIGHT_NODES, warping_nodes,
                                       warping_aspect, warping_field, flat_surface, board_height, board_relief, is_warped, BoardRays,
                                       intersect_board, world_point, board_normal, posed_target, inplane_calibration, placed_chart,
                                       page_fraction, design_chart, physical_chart, page_points
    import VisualGeometryToolkitCore as VgtkCore
    import ForwardDiff
    using StaticArrays: SVector, setindex
    using LinearAlgebra: norm, dot

    tex = fill(0.5, 4, 6, 3)
    𝐨 = SVector(-0.3, -0.2, 1.0); 𝐮 = SVector(0.6, 0.0, 0.0); 𝐯 = SVector(0.0, 0.4, 0.0)
    b = with_facing(TexturedTarget(𝐨, 𝐮, 𝐯, tex), SVector(0.0, 0.0, 0.0))
    @test warping_aspect(b) ≈ 0.4 / 0.6 && length(warping_nodes(warping_aspect(b))) == HEIGHT_NC
    @test b.warping isa VgtkCore.MappedSurface && flat_surface(b.target) isa VgtkCore.MappedSurface
    h0 = zero(SVector{HEIGHT_NC, Float64})
    @test !is_warped(h0) && is_warped(setindex(h0, 1.0e-3, 13))
    D = ForwardDiff.Dual{Nothing, Float64, 1}
    @test !is_warped(D.(h0)) && is_warped(setindex(D.(h0), ForwardDiff.Dual{Nothing}(0.0, 1.0), 13))   # seeded heights count: their partials are needed
    # a flat state: the plane hit, through the target's rays too
    o = SVector(0.0, 0.0, 0.0); x = world_point(b, SVector(0.4, 0.6)); d = x / norm(x)
    @test intersect_board(b, o, d, h0) == intersect_board(b, o, d) == intersect_board(BoardRays(b), o, d)
    # a bump: pure bending (the centre node raised towards the camera), the surface point lies at the field's height over the page
    h = setindex(h0, 2.0e-3, 13)
    bw = with_h(b, h)
    @test board_height(b, h, HEIGHT_NODES[13]) > 0 && board_height(b, h, HEIGHT_NODES) isa Vector{Float64}
    s, xs = intersect_board(BoardRays(bw), o, d)
    @test (s, xs) == intersect_board(b, o, d, h) && isfinite(s) && s < first(intersect_board(b, o, d))      # nearer: the bump faces the camera
    𝐛s = VgtkCore.chart(b, xs)
    @test dot(xs - world_point(b, 𝐛s), board_normal(b)) ≈ board_height(b, h, 𝐛s) atol = 1.0e-9
    @test board_relief(b, h) isa VgtkCore.MappedSurface
    # the warped target as VisualGeometryToolkitCore's posed target: its surface is the render's
    pt = posed_target(bw)
    @test pt isa VgtkCore.PosedTarget && pt !== b.target && posed_target(b, bw.state) isa VgtkCore.PosedTarget
    s2, x2 = VgtkCore.intersection(VgtkCore.surface(pt), o, d)
    @test x2 ≈ xs atol = 1.0e-9
    # the in-plane print error: the design point a physical point shows, and back
    θ = SVector(2.0e-3, -1.0e-3)
    𝐛 = SVector(0.3, 0.7)
    @test design_chart(b, zero(θ), 𝐛) === 𝐛 && physical_chart(b, zero(θ), 𝐛) === 𝐛
    @test physical_chart(b, θ, design_chart(b, θ, 𝐛)) ≈ 𝐛 atol = 1.0e-14
    @test design_chart(with_state(b, TargetState(; inplane = θ)), 𝐛) === design_chart(b, θ, 𝐛) != 𝐛
    @test page_fraction(b, placed_chart(b, 𝐛)) ≈ 𝐛 && inplane_calibration(zero(θ))(SVector(0.3, -0.2)) ≈ SVector(0.3, -0.2)
    # page_points: the surface the render meets
    P = page_points(𝐨, 𝐮, 𝐯, board_normal(b), h, [𝐛s])
    @test only(P) ≈ xs atol = 1.0e-6
    @test page_points(𝐨, 𝐮, 𝐯, board_normal(b), h0, [𝐛]) ≈ [world_point(b, 𝐛)]
end

@testitem "textured target: the albedo at a surface point, and its anchored lookup" begin
    using Test
    using VisualRadiometryToolkitCore: TexturedTarget, TargetState, with_sdf, with_edge, with_inplane, with_state, physical_albedo,
                                       anchored_albedo, printed_albedo, design_chart, physical_chart, world_point
    import VisualGeometryToolkitCore as VgtkCore
    import ForwardDiff
    using StaticArrays: SVector

    # a 1 m page a metre from the origin with a vertical ink edge printed with a 0.03 mm blur (the Siemens print's scale), and an
    # in-plane print error: the distance map's columns 0.25 mm apart, the edge between two of them
    W = 4000; σ = 0.03; xe = 500.0123                                       # mm
    sdf = [1000.0 * (j - 0.5) / W - xe for i in 1:4, j in 1:W]
    b0 = TexturedTarget(SVector(0.7, -0.4, 1.3), SVector(1.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), fill(0.5, 4, 4, 3);
                        facing = SVector(0.0, 0.0, 0.0))
    b = with_inplane(with_edge(with_sdf(b0, sdf, (1000.0, 1000.0)), (0.0, σ)), (1.0e-3, -2.0e-3))
    𝐛 = physical_chart(b, b.state.inplane, SVector((xe + 0.5σ) / 1000, 0.37))   # where the design's edge + σ/2 is printed
    @test physical_albedo(b, 𝐛) === printed_albedo(b, design_chart(b, 𝐛))
    @test 0.6 < physical_albedo(b, 𝐛)[1] < 0.8                               # on the edge's slope

    # the slope along the page's columns (a unit partial of the world point) in Float64, the reference
    𝐱₀ = world_point(b, 𝐛)
    seed(F) = SVector(ForwardDiff.Dual{Nothing}(zero(F), one(F)), ForwardDiff.Dual{Nothing}(zero(F), zero(F)), ForwardDiff.Dual{Nothing}(zero(F), zero(F)))
    D64 = ForwardDiff.Dual{Nothing, Float64, 1}; D32 = ForwardDiff.Dual{Nothing, Float32, 1}
    ref = anchored_albedo(b, 𝐱₀, seed(Float64))
    @test ref isa SVector{3, D64}
    @test ForwardDiff.value(ref[1]) ≈ physical_albedo(b, 𝐛)[1] rtol = 1.0e-12
    slope(ρ) = Float64(ForwardDiff.partials(ρ[1], 1))
    # anchored: the page and its maps in Float64, the state and the offset in a kernel's Float32 numbers — the result in them
    bk = with_state(b, VgtkCore.convert_eltype(Float32, b.state))
    ρa = anchored_albedo(bk, 𝐱₀, seed(Float32))
    @test ρa isa SVector{3, D32}
    @test ForwardDiff.value(ρa[1]) ≈ ForwardDiff.value(ref[1]) rtol = 1.0e-5                 # the edge profile in Float32
    ea = abs(slope(ρa) / slope(ref) - 1)
    # the same lookup in Float32 throughout (the target and the point rounded): the coarse world point moves the slope
    b32 = VgtkCore.convert_eltype(Float32, b)
    en = abs(slope(physical_albedo(b32, VgtkCore.chart(b32, Float32.(𝐱₀) + seed(Float32)))) / slope(ref) - 1)
    println("anchored lookup: slope error $ea anchored, $en in Float32 throughout")
    @test ea < 1.0e-5
    @test ea < en
end

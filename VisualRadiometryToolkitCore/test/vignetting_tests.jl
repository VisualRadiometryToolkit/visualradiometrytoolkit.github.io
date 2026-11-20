@testitem "NoVignetting: V ≡ 1, no parameters" begin
    using Test
    using StaticArrays: SVector
    import VisualGeometryToolkitCore as VgtkCore

    v = NoVignetting()
    u = SVector(1200.0, 800.0)
    f = SVector(0.0, 0.0, 1.0)

    # a vignetting of the stack, a singleton
    @test v isa VgtkCore.AbstractVignetting
    @test Base.issingletontype(NoVignetting) && sizeof(v) == 0

    # V ≡ 1, at a point and at a point with its ray, for every number type the point has
    @test v(u) == 1 && v(u, f) == 1
    @test v(SVector(1.0f0, 2.0f0)) == 1
    # the multiplicative identity of every number type: the product is the other factor, bit for bit
    for x in (0.25, 0.25f0, big"0.25", 3, 1 // 4, -0.0, Inf)
        @test v(u) * x === x || (x isa BigFloat && v(u) * x == x)
    end
    @test isnan(v(u) * NaN)

    # the parameter protocol: nothing to estimate
    @test VgtkCore.parameter_vector(v) === SVector{0, Float64}()
    @test VgtkCore.parameter_names(v) === ()
    lo, hi = VgtkCore.parameter_bounds(v)
    @test isempty(lo) && isempty(hi)
    @test VgtkCore.with_parameters(v, Float64[]) === v
    @test VgtkCore.with_parameters(v, SVector{0, Float32}()) === v
    @test_throws ArgumentError VgtkCore.with_parameters(v, [1.0])
end

@testitem "NoVignetting compiles away" begin
    using Test
    using InteractiveUtils: code_llvm
    using StaticArrays: SVector

    # a kernel that multiplies a radiance by the vignetting at a point
    attenuate(v, u, L) = v(u) * L
    v = NoVignetting()
    u = SVector(1200.0, 800.0)
    @test attenuate(v, u, 0.5) === 0.5
    @test (@inferred attenuate(v, u, 0.5f0)) === 0.5f0
    @test (@allocated attenuate(v, u, 0.5)) == 0
    # the compiled kernel holds no multiplication: the value is a compile-time constant
    ir = sprint(io -> code_llvm(io, attenuate, (NoVignetting, SVector{2, Float64}, Float64); debuginfo = :none))
    @test !occursin("fmul", ir)
end

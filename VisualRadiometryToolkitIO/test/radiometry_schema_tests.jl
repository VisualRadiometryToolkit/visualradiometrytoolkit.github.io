# The radiometric kinds this package owns (moved from VisualGeometryToolkitIO 0.10's radiometry_schema_tests.jl, the
# assertions unchanged): vgio/vignetting/v2.0 (the tensor-product, radial and log fields, rebuilt bit for bit; positions
# in any registered pixel frame, a radial profile's chart always stated), vgio/environment_light/v2.0 (an
# EnvironmentLight of a SphericalHarmonicMap, `max_degree`; a plain light refused; the basis convention pinned), the
# bodies nested in another record, and the validator's refusals.
@testitem "radiometric kinds: vignetting, environment light round trip" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: ProjectiveChart
    using VisualRadiometryToolkitCore: AbstractVignetting, TensorProductVignetting, RadialVignetting, LogVignetting, with_control_points,
        control_points, knot_vectors, EnvironmentLight, SphericalHarmonicMap, coefficients, max_degree
    using VisualGeometryToolkitCore: center, radius, with_unit, Rect
    w(i, j) = 0.5 + 0.0371 * i + 0.0193 * j * j                       # fixed control points, not ones (every entry distinct)
    mktempdir() do dir
        tv = with_control_points(TensorProductVignetting((5, 4), Rect(0.0, 0.0, 640.0, 480.0); degree = (2, 3)), [w(i, j) for i in 1:5, j in 1:4])
        rv = with_control_points(RadialVignetting(7, SVector(320.3, 241.7), 401.25), [w(i, 1) for i in 1:7])
        pv = with_control_points(RadialVignetting(8, SVector(320.3, 241.7), 401.25; chart = ProjectiveChart()), [w(i, 1) for i in 1:8])
        for v in (tv, rv, pv, LogVignetting(rv), LogVignetting(tv), LogVignetting(pv))
            p = joinpath(dir, "v.json")
            save(p, v)
            b = load(AbstractVignetting, p)
            @test typeof(b) == typeof(v) && control_points(b) == control_points(v) && knot_vectors(b) == knot_vectors(v)
            us = (SVector(0.0, 0.0), SVector(100.5, 200.25), SVector(639.0, 479.0))
            @test [b(u) for u in us] == [v(u) for u in us]
            save(joinpath(dir, "v2.json"), b)                                       # what is read writes back byte for byte
            @test read(joinpath(dir, "v2.json")) == read(p)
        end
        d = JSON.parse(read(joinpath(dir, "v.json"), String))
        @test d["schema"] == "vgio/vignetting/v2.0" && d["units"]["pixel"] == "colmap"
        # a radial profile states its chart, ALWAYS: a declaration has no default
        for (v, body, chart) in ((pv, x -> x, "projective"), (rv, x -> x, "linear"), (LogVignetting(rv), x -> x["spline"], "linear"))
            save(joinpath(dir, "r.json"), v)
            b = body(JSON.parse(read(joinpath(dir, "r.json"), String))["vignetting"])
            @test b["chart"] == chart && collect(keys(b)) == ["type", "degree", "center", "radius", "chart", "control_points"]
            @test load(AbstractVignetting, joinpath(dir, "r.json")) == v
        end
        save(joinpath(dir, "r.json"), rv)
        edited(f) = VgtkIO.edited_copy(f, joinpath(dir, "r.json"))   # the record edited into one its reader refuses
        @test_throws ArgumentError load(AbstractVignetting, edited(t -> delete!(t["vignetting"], "chart")))   # v2.0: required
        @test_throws ArgumentError load(AbstractVignetting, edited(t -> t["vignetting"]["chart"] = "polar"))
        # a projective profile of n ≤ 2p control points (written under the knot rule before VisualGeometryToolkitCore 0.10.11)
        # is refused by the record's reader, naming the record, the count and the rule's minimum 2p + 1
        save(joinpath(dir, "r.json"), pv)
        few = edited(t -> t["vignetting"]["control_points"] = t["vignetting"]["control_points"][1:6])
        @test_throws ArgumentError load(AbstractVignetting, few)
        @test_throws r"vgio/vignetting.*projective.*6 control points.*degree 3.*at least 7.*0\.10\.11" load(AbstractVignetting, few)
        save(joinpath(dir, "r.json"), rv)
        L = with_unit(EnvironmentLight(SphericalHarmonicMap([w(i, j) for i in 1:3, j in 1:9], 2), SVector(0.1, -0.2, 0.3), 1.5), m)
        p = joinpath(dir, "light.json")
        save(p, L)
        b = load(EnvironmentLight, p)
        @test coefficients(b) == coefficients(L) && center(b) == center(L) && radius(b) == radius(L) && max_degree(b) == max_degree(L)
        dl = JSON.parse(read(p, String))
        @test dl["schema"] == "vgio/environment_light/v2.0" && dl["units"]["radiance"] == "relative" && dl["units"]["length"] == "mm"
        @test dl["map"]["basis"] == "real_orthonormal_no_condon_shortley" && dl["map"]["max_degree"] == 2 && !haskey(dl["map"], "l_max")
        @test dl["radius"] == 1500.0                                                        # in units.length
        save(joinpath(dir, "light_m.json"), L; length_unit = m)
        @test center(load(EnvironmentLight, joinpath(dir, "light_m.json"))) == center(L)
        @test_throws ArgumentError save(joinpath(dir, "plain.json"), ustrip(m, L))     # a plain light: lengths without units
    end
end

@testitem "radiometric kinds: a vignetting file in any registered pixel frame reads to the same field" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: AbstractVignetting, TensorProductVignetting, RadialVignetting, LogVignetting, with_control_points,
        control_points, knot_vectors
    using VisualGeometryToolkitCore: Rect
    using VisualGeometryToolkitIO: VgioStyle
    w(i, j) = 0.5 + 0.0371 * i + 0.0193 * j * j
    # positions exact in every frame (the frames differ by 0.5 px)
    tv = with_control_points(TensorProductVignetting((5, 4), Rect(0.0, 0.0, 640.0, 480.0); degree = (2, 3)), [w(i, j) for i in 1:5, j in 1:4])
    rv = with_control_points(RadialVignetting(7, SVector(320.25, 241.75), 401.25), [w(i, 1) for i in 1:7])
    mktempdir() do dir
        for v in (tv, rv, LogVignetting(rv)), (frame, shift) in ((:opencv, -0.5), (:julia, 0.5))
            p = joinpath(dir, "v.json")
            save(p, v)                                      # the writer's frame: colmap
            t = JSON.parse(read(p, String))
            t["units"]["pixel"] = String(frame)
            t["vignetting"] = JSON.parse(JSON.json(JSON.lower(VgioStyle(; pixel_frame = PixelFrame{frame}), v)))
            q = joinpath(dir, "v_$(frame).json")
            write(q, JSON.json(t))
            @test VgtkIO.validate(q) == "vignetting"
            b = load(AbstractVignetting, q)
            @test typeof(b) == typeof(v) && control_points(b) == control_points(v)
            @test all(isapprox.(knot_vectors(b), knot_vectors(v); atol = 1.0e-12))
            us = (SVector(0.0, 0.0), SVector(100.5, 200.25), SVector(639.0, 479.0))
            @test all(isapprox(b(u), v(u); atol = 1.0e-12) for u in us)
            # the numbers ARE the frame's: the radial centre moved by the frames' offset
            if v isa RadialVignetting
                @test t["vignetting"]["center"] == [320.25 + shift, 241.75 + shift] && b == v
            end
        end
        # an unregistered pixel frame is refused
        save(joinpath(dir, "v.json"), rv)
        t = JSON.parse(read(joinpath(dir, "v.json"), String)); t["units"]["pixel"] = "lower_left"
        write(joinpath(dir, "bad.json"), JSON.json(t))
        @test_throws ArgumentError load(AbstractVignetting, joinpath(dir, "bad.json"))
    end
end

@testitem "radiometric kinds: the bodies nest in another record (VgioStyle)" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: AbstractVignetting, RadialVignetting, LogVignetting, with_control_points, control_points,
        EnvironmentLight, SphericalHarmonicMap, coefficients
    using VisualGeometryToolkitCore: center, radius, with_unit
    using VisualGeometryToolkitIO: VgioStyle
    s = VgioStyle(; length_unit = mm)
    roundtrip(T, x) = VgtkIO.nested_roundtrip(T, x; style = s)
    v = LogVignetting(with_control_points(RadialVignetting(6, SVector(320.0, 240.0), 400.0), [0.5 + 0.01i for i in 1:6]))
    @test control_points(roundtrip(AbstractVignetting, v)) == control_points(v)
    L = with_unit(EnvironmentLight(SphericalHarmonicMap(ones(3, 4), 1), SVector(0.1, -0.2, 0.3), 1.5), m)
    b = roundtrip(EnvironmentLight, L)
    @test center(b) == center(L) && radius(b) == radius(L) && coefficients(b) == coefficients(L)
    @test JSON.lower(s, L).radius == 1500.0                                       # in the style's unit
end

@testitem "radiometric kinds: the validator" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: RadialVignetting, AbstractVignetting, EnvironmentLight, SphericalHarmonicMap
    using VisualGeometryToolkitCore: with_unit
    mktempdir() do dir
        edited(src, f) = VgtkIO.edited_copy(f, src)
        p = joinpath(dir, "v.json")
        save(p, RadialVignetting(5, SVector(10.0, 20.0), 30.0))
        @test_throws ArgumentError load(AbstractVignetting, edited(p, t -> t["vignetting"]["type"] = "polynomial"))
        # a retired tag: the registry's message, naming its successor
        err = try load(AbstractVignetting, edited(p, t -> t["vignetting"]["type"] = "tensor")); nothing catch e; e end
        @test err isa ArgumentError && occursin("tensor_product", err.msg) && occursin("renamed", err.msg)
        @test_throws ArgumentError load(AbstractVignetting, edited(p, t -> t["pixel_frame"] = "opencv"))     # IO 0.9's declaration: unknown key
        @test_throws ArgumentError load(AbstractVignetting, edited(p, t -> delete!(t["units"], "pixel")))    # the envelope's
        l = joinpath(dir, "l.json")
        save(l, with_unit(EnvironmentLight(SphericalHarmonicMap(ones(3, 4), 1), SVector(0.0, 0.0, 0.0), 1.0), m))
        @test_throws ArgumentError load(EnvironmentLight, edited(l, t -> t["map"]["basis"] = "complex_condon_shortley"))
        err = try load(EnvironmentLight, edited(l, t -> t["map"]["coefficients"][1] = [1.0, 2.0])); nothing catch e; e end   # (max_degree+1)² per channel
        @test err isa ArgumentError && occursin("max_degree", err.msg)
        @test_throws ArgumentError load(EnvironmentLight, edited(l, t -> t["map"]["l_max"] = pop!(t["map"], "max_degree")))   # IO 0.9's key
        @test_throws ArgumentError load(EnvironmentLight, edited(l, t -> t["units"]["radiance"] = "W/m^2/sr"))
    end
end

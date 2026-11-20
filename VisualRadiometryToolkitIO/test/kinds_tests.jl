# What the kinds are in VisualGeometryToolkitIO's terms: each file opens with its envelope and names its schema as before
# the move; the generic validator and a calibration manifest reach the kinds through this package's `validate_record`
# methods; the published JSON Schemas (docs/src/schemas) are the generator's output; a body's table embeds in a kind of
# another package.

@testitem "kinds: the envelope and the schema names are VisualGeometryToolkitIO's, unchanged; validate and a manifest reach them" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: AbstractVignetting, RadialVignetting, LogVignetting, with_control_points, EnvironmentLight,
        SphericalHarmonicMap, BinnedRadialProfile
    using VisualGeometryToolkitCore: with_unit
    values = [
        "vignetting" => (AbstractVignetting, LogVignetting(with_control_points(RadialVignetting(6, SVector(320.0, 240.0), 400.0), [0.5 + 0.01i for i in 1:6])), "vgio/vignetting/v2.0"),
        "environment_light" => (EnvironmentLight, with_unit(EnvironmentLight(SphericalHarmonicMap(ones(3, 4), 1), SVector(0.1, -0.2, 0.3), 1.5), m), "vgio/environment_light/v2.0"),
        "radial_profile" => (BinnedRadialProfile, BinnedRadialProfile(:linear, SVector(2120.5, 1416.25), 2551.0, [0.0, 0.25, 0.5, 1.0], [0.9 0.8 0.6; 0.95 0.85 0.7], [100, 300, 900]), "vgio/radial_profile/v1.0"),
    ]
    mktempdir() do dir
        for (kind, (T, value, schema)) in values
            p = joinpath(dir, "$(kind).json")
            save(p, value; provenance = (run = "a",))
            d = JSON.parse(read(p, String))                     # (key order kept)
            @test collect(keys(d))[1:4] == ["schema", "generator", "units", "conventions"] && last(collect(keys(d))) == "provenance"
            @test d["schema"] == schema
            @test d["generator"] == Dict("name" => "VisualGeometryToolkitIO", "version" => string(pkgversion(VgtkIO)))
            @test collect(keys(d["units"])) == ["length", "time", "angle", "pixel", "density", "radiance", "length_roles"]
            @test VgtkIO.validate(p) == kind                    # the generic validator, through this package's check
            back = load(T, p)
            q = joinpath(dir, "again.json")
            save(q, back; provenance = (run = "a",))
            @test read(q) == read(p)                            # what is read writes back byte for byte
            # a higher minor's added key is tolerated; an unknown key at the reader's own minor is refused, by name
            t = JSON.parse(read(p, String); dicttype = Dict{String, Any})
            t["added"] = 1
            write(q, JSON.json(t))
            @test_throws r"added" load(T, q)
            t["schema"] = replace(schema, r"\.0$" => ".1")
            write(q, JSON.json(t))
            @test load(T, q) isa T
            # a later major, and a file of another kind, are refused
            t["schema"] = replace(schema, r"v\d+\.0$" => "v9.0")
            write(q, JSON.json(t))
            @test_throws r"later major" load(T, q)
        end
        @test_throws ArgumentError load(AbstractVignetting, joinpath(dir, "environment_light.json"))
        # a manifest lists the kinds' files, and reading it checks each one by this package's tables
        VgtkIO.save_manifest(dir, ["vignetting.json", "environment_light.json", "radial_profile.json"]; result_kind = "image")
        @test length(VgtkIO.load_manifest(dir).files) == 3
        t = JSON.parse(read(joinpath(dir, "vignetting.json"), String); dicttype = Dict{String, Any})
        t["vignetting"]["spline"]["chart"] = "polar"
        write(joinpath(dir, "vignetting.json"), JSON.json(t))
        @test_throws ArgumentError VgtkIO.validate(joinpath(dir, "vignetting.json"))
    end
end

@testitem "kinds: the published JSON Schemas are the generator's output" setup = [VRIoFixtures] begin
    import VisualRadiometryToolkitIO
    schemas = VisualRadiometryToolkitIO.json_schemas()
    @test first.(schemas) == ["vgio/environment_light/v2.0.json", "vgio/radial_profile/v1.0.json", "vgio/vignetting/v2.0.json"]
    dir = joinpath(pkgdir(VisualRadiometryToolkitIO), "docs", "src", "schemas")
    published = String[]
    for (root, _, files) in walkdir(dir), f in files
        push!(published, replace(relpath(joinpath(root, f), dir), '\\' => '/'))
    end
    @test sort(published) == first.(schemas)                  # every kind's schema is published, and none other
    for (path, schema) in schemas
        @test schema["\$id"] == "https://visualradiometrytoolkit.github.io/schemas/" * path
        @test schema["title"] * ".json" == path && occursin("as VisualRadiometryToolkitIO writes and reads it", schema["description"])
        # (regenerate: write(joinpath(dir, path), JSON.json(schema; pretty = 4)) for each pair of json_schemas())
        @test read(joinpath(dir, path), String) == JSON.json(schema; pretty = 4)
    end
    v = last(last(schemas))                                   # the vignetting body: one definition, a log field's spline refers to it
    @test v["properties"]["vignetting"] == Dict("\$ref" => "#/\$defs/vignetting") && length(v["\$defs"]["vignetting"]["oneOf"]) == 3
end

@testitem "kinds: a body's table embeds in a kind of another package" setup = [VRIoFixtures] begin
    import VisualRadiometryToolkitIO
    using VisualRadiometryToolkitCore: AbstractVignetting, RadialVignetting, with_control_points, EnvironmentLight, SphericalHarmonicMap,
        BinnedRadialProfile
    using VisualGeometryToolkitCore: with_unit
    HOLDER = VgtkIO.KindSpec("toy/holder/v1.0",
        [:vignetting => VisualRadiometryToolkitIO.VIGNETTING_BODY, :light => VisualRadiometryToolkitIO.ENVIRONMENT_LIGHT_BODY],
        [:profile => VisualRadiometryToolkitIO.RADIAL_PROFILE_BODY]; package = "Toy")
    v = with_control_points(RadialVignetting(7, SVector(320.25, 241.75), 401.25), [0.5 + 0.03i for i in 1:7])
    L = with_unit(EnvironmentLight(SphericalHarmonicMap(ones(3, 4), 1), SVector(0.1, -0.2, 0.3), 1.5), m)
    p = BinnedRadialProfile(:linear, SVector(100.0, 50.0), 80.0, [0.0, 0.5, 1.0], [0.9 0.7], [10, 20])
    mktempdir() do dir
        path = joinpath(dir, "holder.json")
        style = VgtkIO.VgioStyle(; length_unit = m, pixel_frame = PixelFrame{:opencv})
        VgtkIO.write_kind(path, HOLDER, (vignetting = v, light = L, profile = p); style)   # each value lowered on the style
        r = VgtkIO.read_kind(path, HOLDER)
        s = VgtkIO.VgioStyle(r)
        @test r.vignetting.center == [319.75, 241.25] && r.light.radius == 1.5 && r.profile.chart.center == [99.5, 49.5]
        @test JSON.lift(s, AbstractVignetting, r.vignetting) == v
        @test JSON.lift(s, BinnedRadialProfile, r.profile) == p
        back = JSON.lift(s, EnvironmentLight, r.light)
        @test VgtkIO.same_value(back, L)
        @test_throws r"vignetting" VgtkIO.write_kind(joinpath(dir, "refused.json"), HOLDER, (vignetting = (type = "radial",), light = L); style)
        @test !isfile(joinpath(dir, "refused.json"))
    end
end

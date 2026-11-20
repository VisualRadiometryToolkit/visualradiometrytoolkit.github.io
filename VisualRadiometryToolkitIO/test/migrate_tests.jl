# The version steps of the kinds (moved from VisualGeometryToolkitIO 0.10's migrate_v010_tests.jl, the assertions
# unchanged, on the same fixtures): a vgio/vignetting/v1 and a vgio/environment_light/v1 file — written by
# VisualGeometryToolkitIO 0.9 — reads through its step, and `vgio_migrate` rewrites it once; the versions read are
# derived from the steps.

@testitem "migrate: every IO 0.9 file of these kinds reads through its step and vgio_migrate rewrites it" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: AbstractVignetting, EnvironmentLight
    using VisualGeometryToolkitIO: vgio_migrate
    files = ["vignetting_v1_linear.json" => AbstractVignetting, "vignetting_v1_chart.json" => AbstractVignetting,
             "environment_light_v1.json" => EnvironmentLight]
    mktempdir() do dir
        for (name, T) in files
            src = old_fixture(name)
            value = load(T, src)
            out = joinpath(dir, "migrated_" * name)
            r = vgio_migrate(src; out)
            kind = VgtkIO.validate(out)
            @test r.from == old_tree(src)["schema"] && r.to == old_tree(out)["schema"] && r.out == out
            @test kind in ("vignetting", "environment_light") && startswith(r.to, "vgio/$(kind)/v2.")
            @test VgtkIO.same_value(load(T, out), value)                     # the migrated file reads as the old one did
            @test vgio_migrate(src; dry_run = true).out === nothing            # verified, nothing written
            @test_throws ArgumentError vgio_migrate(out; out = joinpath(dir, "again.json"))   # a current file: nothing to migrate
        end
    end
end

@testitem "migrate: vignetting v1 with and without its chart; environment light v1" setup = [VRIoFixtures] begin
    using VisualRadiometryToolkitCore: AbstractVignetting, RadialVignetting, LogVignetting, radial_chart, log_spline,
        EnvironmentLight, max_degree
    import VisualRadiometryToolkitIO
    v = load(AbstractVignetting, old_fixture("vignetting_v1_linear.json"))
    @test v isa RadialVignetting && radial_chart(v) === :linear
    w = load(AbstractVignetting, old_fixture("vignetting_v1_chart.json"))
    @test w isa LogVignetting && radial_chart(log_spline(w)) === :projective
    t = VgtkIO.migrate_record(old_tree(old_fixture("vignetting_v1_linear.json")))
    @test t["schema"] == "vgio/vignetting/v2.0" && t["vignetting"]["chart"] == "linear" && t["units"]["pixel"] == "colmap"
    @test max_degree(load(EnvironmentLight, old_fixture("environment_light_v1.json"))) == 1
    t = VgtkIO.migrate_record(old_tree(old_fixture("environment_light_v1.json")))
    @test t["schema"] == "vgio/environment_light/v2.0"
    @test t["map"]["max_degree"] == 1 && !haskey(t["map"], "l_max") && t["units"]["length"] == "mm"
    # the body's step alone, for a record of another package that embeds a v1 body
    radial = Dict{String, Any}("type" => "radial", "degree" => 3)
    @test VisualRadiometryToolkitIO.migrate_vignetting_body(radial)["chart"] == "linear"
    @test VisualRadiometryToolkitIO.migrate_vignetting_body(merge(radial, Dict("chart" => "projective")))["chart"] == "projective"
    @test VisualRadiometryToolkitIO.migrate_vignetting_body(Dict{String, Any}("type" => "log", "spline" => radial))["spline"]["chart"] == "linear"
    tensor = Dict{String, Any}("type" => "tensor_product")
    @test VisualRadiometryToolkitIO.migrate_vignetting_body(tensor) == tensor
    # the versions read, derived from the steps
    @test VgtkIO.schema_versions(VisualRadiometryToolkitIO.VIGNETTING_KIND) == ["vgio/vignetting/v1", "vgio/vignetting/v2.0"]
    @test VgtkIO.schema_versions(VisualRadiometryToolkitIO.ENVIRONMENT_LIGHT_KIND) == ["vgio/environment_light/v1", "vgio/environment_light/v2.0"]
    @test VgtkIO.schema_versions(VisualRadiometryToolkitIO.RADIAL_PROFILE_KIND) == ["vgio/radial_profile/v1.0"]
end

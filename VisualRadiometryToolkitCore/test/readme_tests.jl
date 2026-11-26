# readme_tests.jl — the README's example and the documentation's first example
# run as written, in a clean environment that holds exactly what the README's
# install line adds. A reader's first contact with the package is that code.
#
# The install line is a `pkg> add` line in a ```julia-repl block, so it is not run as code:
# the item checks that it names every non-standard-library package the example
# loads, and nothing else. The example then runs in a child Julia process in a
# temporary environment (this package by path, the rest of the install line
# from the registries), with none of the test run's load path. The check is
# VisualGeometryToolkitCore's; this package holds no copy of it.

@testitem "README: the install line names what the example loads; the example runs in a fresh environment" begin
    using Test
    import VisualGeometryToolkitCore as VgtkCore
    VgtkCore.test_readme_example(pkgdir(VisualRadiometryToolkitCore);
        # TEMPORARY: solve branch; remove when Core 0.14 etc. are registered (no registry has Core 0.14 yet)
        developed = Dict("VisualGeometryToolkitCore" => pkgdir(VgtkCore)), checks = """
    # What the example's comments claim: no vignetting was stated, the focus
    # point is at the focus distance, and the back-projected direction is unit.
    @test readme.camera isa readme.RadiometricCameraModel
    @test readme.camera.vignetting isa readme.NoVignetting
    @test readme.norm(readme.d) ≈ 1
    """)
end

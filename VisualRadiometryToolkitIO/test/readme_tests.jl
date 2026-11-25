# readme_tests.jl — the README's example and the documentation's first example
# run as written, in a clean environment that holds exactly what the README's
# install line adds. A reader's first contact with the package is that code.
#
# The install line is a `pkg> add` line in a ```julia-repl block, so it is not run as code:
# the item checks that it names every non-standard-library package the example
# loads, and nothing else. The example then runs in a child Julia process in a
# temporary environment (this package and VisualRadiometryToolkitCore by path:
# both are workspace members, developed together; the rest of the install line
# from the registries), with none of the test run's load path. The check is
# VisualGeometryToolkitCore's; this package holds no copy of it.

@testitem "README: the install line names what the example loads; the example runs in a fresh environment" begin
    using Test
    import VisualGeometryToolkitCore as VgtkCore
    import VisualRadiometryToolkitCore
    import VisualGeometryToolkitIO   # TEMPORARY: solve branch; remove when Core 0.14 etc. are registered
    VgtkCore.test_readme_example(pkgdir(VisualRadiometryToolkitIO);
        developed = Dict("VisualRadiometryToolkitCore" => pkgdir(VisualRadiometryToolkitCore),
                         # TEMPORARY: solve branch; remove when Core 0.14 etc. are registered (no registry has IO 0.12 yet)
                         "VisualGeometryToolkitIO" => pkgdir(VisualGeometryToolkitIO)), checks = """
    # What the example's comments claim: the file exists, and the field read
    # back is the radial field that was written.
    @test isfile(readme.path)
    @test readme.VgtkIO.load(readme.AbstractVignetting, readme.path) isa readme.RadialVignetting
    """)
end

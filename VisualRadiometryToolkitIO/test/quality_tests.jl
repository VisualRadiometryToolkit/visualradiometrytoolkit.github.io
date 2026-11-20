# =============================================================================
# Tooling gates — the Visual Geometry Toolkit's, run on this package
# =============================================================================
#
# The stack's conventions are VisualGeometryToolkitCore's, and so are the gates
# that enforce them: this package calls them and holds no copy.

@testitem "quality: the stack's gates (test_quality_gates)" begin
    # Aqua, ExplicitImports and JET at this package's bounds; the stack
    # contracts (no private name of another stack package, methods on another
    # stack package's functions only on its contract generics); the dependency
    # allow-list, with this repository's rows.
    using Test, Aqua, ExplicitImports, JET
    import VisualGeometryToolkitCore as VgtkCore
    VgtkCore.test_quality_gates(
        VisualRadiometryToolkitIO;
        jet_bound = 0,
        stack_extra = # this repository's rows of the allow-list, kept with VisualRadiometryToolkitCore (the workspace is the unit tested)
        joinpath(dirname(pkgdir(VisualRadiometryToolkitIO)), "VisualRadiometryToolkitCore", "configs", "stack_dependencies.toml"),
    )
end

@testitem "quality: naming" begin
    # The stack's naming rules (VisualGeometryToolkitCore's check_naming).
    import VisualGeometryToolkitCore as VgtkCore
    using Test
    VgtkCore.test_naming(VisualRadiometryToolkitIO)
end

@testitem "quality: no duplication" begin
    # One implementation per concept (VisualGeometryToolkitCore's check_duplication;
    # the exceptions are the repository root's DUPLICATION.toml).
    import VisualGeometryToolkitCore as VgtkCore
    using Test
    VgtkCore.test_duplication(VisualRadiometryToolkitIO)
end

@testitem "docs: every public name has a docstring, attached, and its signatures match the methods" begin
    using Test
    using VisualGeometryToolkitCore: test_docs
    test_docs(VisualRadiometryToolkitIO)
end

@testitem "agent docs" begin
    # CLAUDE.md ships with the package: it carries its conventions and nothing
    # private. The check and its patterns are VisualGeometryToolkitCore's.
    using Test
    using VisualGeometryToolkitCore: agent_doc_violations
    violations = agent_doc_violations(pkgdir(VisualRadiometryToolkitIO); extra = get(ENV, "AGENT_DOC_PATTERNS", nothing))
    isempty(violations) || @error "agent docs carry private content" violations
    @test isempty(violations)
end

@testitem "the skeleton: an empty module" begin
    # Nothing is defined yet: the kinds arrive with the types they hold.
    using Test
    @test isempty(setdiff(names(VisualRadiometryToolkitIO), (:VisualRadiometryToolkitIO,)))
    @test pkgversion(VisualRadiometryToolkitIO) == v"0.0.1"
end

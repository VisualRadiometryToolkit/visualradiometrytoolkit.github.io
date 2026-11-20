# =============================================================================
# VisualRadiometryToolkitCore test suite — ReTestItems
# =============================================================================
#
# Every `*_tests.jl` file under test/ is discovered automatically. Each holds
# `@testitem`s, and each item is evaluated in its own module on a pool of
# worker processes: items share no bindings and run in no fixed order, so an
# item imports and defines everything it uses.
#
#   Pkg.test()                                   # every item, in parallel
#   Pkg.test(; test_args = ["vignetting"])       # items whose name matches
#   RETESTITEMS_NWORKERS=0 → serial, in-process  # for debugging
#   julia --project=test test/runtests.jl vignetting_tests.jl   # one file (an argument naming a file in test/)
#
# Default: one worker per two logical CPUs (each worker runs 2 threads).
# =============================================================================

using ReTestItems
using VisualRadiometryToolkitCore

const FILES = [joinpath(@__DIR__, a) for a in ARGS if endswith(a, ".jl")]
const NAMES = filter(a -> !endswith(a, ".jl"), ARGS)
# (with files: the package's `src` first, which holds no item, so ReTestItems takes the package's
# Project.toml as the project, not test/'s)
runtests(
    (isempty(FILES) ? (VisualRadiometryToolkitCore,) : (joinpath(pkgdir(VisualRadiometryToolkitCore), "src"), FILES...))...;
    nworkers = parse(Int, get(ENV, "RETESTITEMS_NWORKERS", string(max(1, Sys.CPU_THREADS ÷ 2)))),
    name = isempty(NAMES) ? nothing : Regex(join(NAMES, "|")),
)

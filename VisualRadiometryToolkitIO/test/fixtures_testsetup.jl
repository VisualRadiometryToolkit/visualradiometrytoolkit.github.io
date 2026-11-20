# =============================================================================
# VRIoFixtures — the prelude every item shares
# =============================================================================
#
# Pulled into an item by `setup = [VRIoFixtures]`: VisualGeometryToolkitIO's two
# verbs (unexported there; this package adds its kinds' methods to them), JSON,
# the units and the few geometry names the items build values from. An item sees
# a setup's EXPORTED names only; anything beyond these it imports itself.

@testsetup module VRIoFixtures
    import VisualGeometryToolkitIO as VgtkIO
    using JSON: JSON
    using VisualGeometryToolkitIO: load, save
    using StaticArrays: SVector, SMatrix
    using VisualGeometryToolkitCore: mm, m, PixelFrame
    using FlexUnits: ustrip

    export VgtkIO, JSON, load, save, SVector, SMatrix, mm, m, PixelFrame, ustrip, old_fixture, old_tree

    # A file an earlier VisualGeometryToolkitIO wrote (test/fixtures/old), and its parsed record (String keys).
    old_fixture(name) = joinpath(@__DIR__, "fixtures", "old", name)
    old_tree(path) = JSON.parse(read(path, String); dicttype = Dict{String, Any})
end

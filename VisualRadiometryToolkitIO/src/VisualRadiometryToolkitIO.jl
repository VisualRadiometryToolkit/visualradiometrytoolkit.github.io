"""
    VisualRadiometryToolkitIO

The file formats of the Visual Radiometry Toolkit: the radiometric types of
VisualRadiometryToolkitCore saved and loaded as self-describing files, in the
envelope and under the schema rules of VisualGeometryToolkitIO.

Under construction (version 0.0.1, not registered): the package is an empty
skeleton. The radiometric file kinds move here from VisualGeometryToolkitIO
with the types they hold (docs/design/inventory.md in the repository).
"""
module VisualRadiometryToolkitIO

# -----------------------------------------------------------------------------
# The layout (planned; nothing is included yet). The package will depend on
# VisualRadiometryToolkitCore (the types), VisualGeometryToolkitCore and
# VisualGeometryToolkitIO (the envelope, the validator, the version steps); the
# dependencies are added with the first kind, not before: an unused dependency
# fails the quality gates.
# -----------------------------------------------------------------------------

# include("vignetting_schema.jl")         # the vignetting kind
# include("environment_light_schema.jl")  # the environment-light kind
# include("radial_profile_schema.jl")     # the radial-profile kind

end # module

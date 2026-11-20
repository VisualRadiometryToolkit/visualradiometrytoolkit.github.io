"""
    VisualRadiometryToolkitCore

The core of the Visual Radiometry Toolkit: the types of a radiometric camera, a
camera of the Visual Geometry Toolkit (VisualGeometryToolkitCore) together with
the parts that decide how much light a pixel collects. Radiometry lifts
geometry: this package depends on VisualGeometryToolkitCore and follows its
conventions; nothing there depends on this.

Under construction (version 0.0.1, not registered). It holds the first part
born here, [`NoVignetting`](@ref); the rest of the layout is planned in the
comments of this file and in the manual's *Design* page.
"""
module VisualRadiometryToolkitCore

using StaticArrays: SVector, StaticVector
using VisualGeometryToolkitCore: AbstractVignetting
import VisualGeometryToolkitCore: parameter_vector, parameter_names, with_parameters

export NoVignetting

# -----------------------------------------------------------------------------
# The layout. A file that is commented out is planned: its contents exist today
# in VisualGeometryToolkitCore or in RadiometricCamera and move here in the
# order of docs/design/inventory.md (in the repository). Each camera part is an
# abstract type whose `No…` default is a singleton that compiles away.
# -----------------------------------------------------------------------------

# The camera's parts ---------------------------------------------------------
include("camera/vignetting.jl")        # NoVignetting (born here); the vignetting fields and their protocol move here
# include("camera/aperture.jl")        # the aperture part and its absent default (a pinhole)
# include("camera/focus.jl")           # the focus part: focus surfaces and the absent default (everything in focus)
# include("camera/blur.jl")            # the blur part and its absent default
# include("camera/response.jl")        # the sensor response part (gain, exposure, levels, response curve) and its absent default
# include("camera/radiometric_camera.jl")  # the radiometric camera: a geometric camera and its parts

# The scene's light and surfaces ----------------------------------------------
# include("scene/lights.jl")           # lights; the environment light and its radiance map
# include("scene/materials.jl")        # materials and reflectance

# Evaluation -------------------------------------------------------------------
# include("radiance/quadrature.jl")    # the integrals over the aperture and the pixel footprint
# include("radiance/kernels.jl")       # the rendering kernels, one implementation for every backend

end # module

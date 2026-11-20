"""
    VisualRadiometryToolkitCore

The core of the Visual Radiometry Toolkit: the types of a radiometric camera, a
camera of the Visual Geometry Toolkit (VisualGeometryToolkitCore) together with
the parts that decide how much light a pixel collects, and of the scene's light.
Radiometry lifts geometry: this package depends on VisualGeometryToolkitCore and
follows its conventions; nothing there depends on this.

- A camera's vignetting: [`NoVignetting`](@ref) (absent, `V ≡ 1`), the B-spline
  fields [`TensorProductVignetting`](@ref) and [`RadialVignetting`](@ref), the
  log-domain [`LogVignetting`](@ref), and a measured [`BinnedRadialProfile`](@ref).
- The scene's light: an [`EnvironmentLight`](@ref) of a
  [`SphericalHarmonicMap`](@ref).
"""
module VisualRadiometryToolkitCore

using StaticArrays: SVector, SMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, dot
using ForwardDiff: ForwardDiff
using GeometryBasics: GeometryBasics
using CoordinateTransformations: CoordinateTransformations
using FlexUnits: FlexUnits, Units
using VisualGeometryToolkitCore: bspline_basis, clamped_knots, HomographyMap, TagRegistry, LocalSupport, Rect2,
    primal_value, strip_pixels, strip_point, attach_point, attach_length, strip_or_bare
# VisualGeometryToolkitCore's contract generics these types answer: a field's centre and element type, the support
# protocol of a surface's control points, the parameter protocol, a light's units
import VisualGeometryToolkitCore: center, convert_eltype, support_trait, nodes, support,
    parameter_vector, parameter_names, with_parameters, has_units, with_unit

export AbstractVignetting, NoVignetting, TensorProductVignetting, RadialVignetting, LogVignetting   # a camera's vignetting (camera/vignetting.jl)
public log_spline        # a LogVignetting's spline of log V
public VIGNETTING_TAGS   # the fields' TagRegistry: the `type` of VisualRadiometryToolkitIO's vignetting body
public coefficient_jacobian, active_coefficients, control_points, with_control_points, n_control_points, knot_vectors, spline_degree,
       field_radius, radial_coordinate, pole_regular_basis   # the fields' basis, accessors and a radial profile's regular subspace
public RADIAL_CHARTS, BinnedRadialProfile, projective_chart, projective_knots, radial_chart, with_center, center_gradient   # a radial profile's chart and centre; a measured profile
export EnvironmentLight, SphericalHarmonicMap   # the scene's light: radiance from every direction on a sphere about a centre, in real SH (scene/lights.jl)
public radiance, exit_direction, radiance_map, coefficients, with_coefficients, max_degree, sh_basis, sh_count, sh_index   # its evaluation, accessors and the SH basis

# The camera's parts ---------------------------------------------------------
include("camera/vignetting.jl")        # the vignetting fields and their protocol; NoVignetting, the absent one

# The scene's light -----------------------------------------------------------
include("scene/lights.jl")             # EnvironmentLight, SphericalHarmonicMap, sh_basis (extends vignetting.jl's coefficient_jacobian)

end # module

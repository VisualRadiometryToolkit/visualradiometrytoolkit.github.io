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
- A camera's focus surface: [`Focus`](@ref), the inverse focus distance along each
  chief ray as a thin plate spline.
- The radiometric camera, one object: [`RadiometricCameraModel`](@ref), a geometric
  camera with its focus surface, aperture radius and vignetting, and its
  back-projection from the aperture disc (`π̂⁻¹`, `world_ray`).
- The sensor's pixels and the quadrature rules of the image-formation integrals:
  [`SensorQuadrature`](@ref) on a pixel, [`ApertureQuadrature`](@ref) on the aperture.
- The scene's light: an [`EnvironmentLight`](@ref) of a
  [`SphericalHarmonicMap`](@ref).
- A surface's reflectance: [`Material`](@ref), a spatially varying Cook–Torrance
  BSDF with a GGX microfacet distribution.
"""
module VisualRadiometryToolkitCore

using StaticArrays: SVector, SMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, dot, normalize
using QuadGK: gauss   # the Gauss–Legendre nodes of the sensor rule (sensor/quadrature.jl)
using ForwardDiff: ForwardDiff
using GeometryBasics: GeometryBasics
using CoordinateTransformations: CoordinateTransformations
using FlexUnits: FlexUnits, Units
using VisualGeometryToolkitCore: bspline_basis, clamped_knots, HomographyMap, TagRegistry, LocalSupport, Rect2,
    primal_value, strip_pixels, strip_point, attach_point, attach_length, strip_or_bare
using VisualGeometryToolkitCore: EuclideanMap, PixelFrame, unlabel   # a pose (camera → world) and the pixel conventions' origin map
using VisualGeometryToolkitCore: BoundedCamera, CameraModel, AbstractIntrinsics, SplineLens, extent, model, normalized_point   # the geometric camera a radiometric camera lifts
using VisualGeometryToolkitCore: grid_nodes, square_rule, unit_disc_rule   # a focus surface's sensor grid; the quadrature rules
using GeometryBasics: Rect
import VisualGeometryToolkitCore as VgtkCore   # the spline systems of a focus surface and the equidistant chart, reached qualified (camera/focus.jl, focus_charts.jl)
# VisualGeometryToolkitCore's contract generics these types answer: a field's centre and element type, the support
# protocol of a surface's control points, the parameter protocol, a light's units
import VisualGeometryToolkitCore: center, convert_eltype, support_trait, nodes, support,
    parameter_vector, parameter_names, with_parameters, has_units, with_unit,
    project, backproject   # a radiometric camera's geometric maps, forwarded to its geometric camera

export AbstractVignetting, NoVignetting, TensorProductVignetting, RadialVignetting, LogVignetting   # a camera's vignetting (camera/vignetting.jl)
public log_spline        # a LogVignetting's spline of log V
public VIGNETTING_TAGS   # the fields' TagRegistry: the `type` of VisualRadiometryToolkitIO's vignetting body
public coefficient_jacobian, active_coefficients, control_points, with_control_points, n_control_points, knot_vectors, spline_degree,
       field_radius, radial_coordinate, pole_regular_basis   # the fields' basis, accessors and a radial profile's regular subspace
public RADIAL_CHARTS, BinnedRadialProfile, projective_chart, projective_knots, radial_chart, with_center, center_gradient   # a radial profile's chart and centre; a measured profile
export EnvironmentLight, SphericalHarmonicMap   # the scene's light: radiance from every direction on a sphere about a centre, in real SH (scene/lights.jl)
public radiance, exit_direction, radiance_map, coefficients, with_coefficients, max_degree, sh_basis, sh_count, sh_index   # its evaluation, accessors and the SH basis

export RadiometricCameraModel   # the radiometric camera: a geometric camera with its focus surface, aperture radius and vignetting (camera/radiometric_camera.jl)
public geometric, focus, aperture_radius, with_geometric, with_focus, with_aperture_radius, with_vignetting   # its parts and their replacers
public chief_ray, chief_dir, 𝔭, 𝔣, π̂⁻¹, world_ray   # its camera-frame maps: the chief ray, the focus point, the back-projection from the aperture, a ray in the world
public Focus, FocusSpline, n_nodes, t̂, 𝔱   # the focus surface: the inverse focus distance as a thin plate spline, and its host-side solver (camera/focus.jl)
public FOCUS_SENSOR, FOCUS_DIRECTION_CHART, FOCUS_SPHERE, ae_chart, ae_dir, t̂_dir, focus_weights, polar_cap_nodes   # the focus kinds: the sensor chart, a direction chart, the sphere (camera/focus_charts.jl)
public 𝐩_of_pixel, pixel_of_𝐩, ℐ_𝐮, luma, luma_image   # the sensor domain: Julia's pixel indices and sensor positions, a pixel's footprint, luma (sensor/notation.jl)
public SensorQuadrature, ApertureQuadrature, sensor_samples, aperture_samples, aperture_border, 𝐩_sample, 𝐚_sample, 𝐚_weight, 𝐚_border,
       n_disc, n_border   # the rules on a pixel and on the aperture disc and its border (sensor/quadrature.jl)
public Material, Θ_m_nonlinear, with_nonlinear, with_μ, texture_weight, 𝛂, 𝛈, D_ggx, Λ_ggx, G1_ggx, G2_ggx, F_dielectric,
       sample_vndf_caps, D_v, PDF_reflect, reflect, f_CT_parts, f_CT   # a surface's reflectance: the Cook–Torrance BSDF and its GGX pieces (scene/materials.jl)
public CONTRACT_GENERICS   # the functions another package may add methods to

# The sensor ------------------------------------------------------------------
include("sensor/notation.jl")          # sensor positions and Julia's pixels, a pixel's footprint, luma
include("sensor/quadrature.jl")        # the quadrature rules of the image-formation integrals

# The camera's parts ---------------------------------------------------------
include("camera/vignetting.jl")        # the vignetting fields and their protocol; NoVignetting, the absent one
include("camera/focus.jl")             # the focus surface and its host-side solver
include("camera/focus_charts.jl")      # the focus kinds on the chief directions
include("camera/radiometric_camera.jl") # the radiometric camera and its back-projection from the aperture

# The scene's light -----------------------------------------------------------
include("scene/lights.jl")             # EnvironmentLight, SphericalHarmonicMap, sh_basis (extends vignetting.jl's coefficient_jacobian)
include("scene/materials.jl")          # Material: the spatially varying Cook–Torrance BSDF

"""
    CONTRACT_GENERICS

The generic functions of VisualRadiometryToolkitCore another package may add
methods to across a package boundary (VisualGeometryToolkitCore's
`contract_generic_violations` reads this tuple):

- [`chief_ray`](@ref): a geometric camera type of another package answers it to
  carry a radiometric camera;
- the camera-frame maps a record holding a radiometric camera's parts forwards
  to their one implementation: [`chief_dir`](@ref), [`t̂`](@ref), [`𝔣`](@ref),
  [`π̂⁻¹`](@ref), [`world_ray`](@ref);
- the part accessors such a record answers: [`geometric`](@ref), [`focus`](@ref),
  [`aperture_radius`](@ref).
"""
const CONTRACT_GENERICS = (chief_ray, chief_dir, t̂, 𝔣, π̂⁻¹, world_ray, geometric, focus, aperture_radius)

end # module

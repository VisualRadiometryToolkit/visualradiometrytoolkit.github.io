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
  back-projection from the aperture disc (`backproject(camera, 𝐩, 𝐚)`, the paper's `π̂⁻¹`; `world_ray`).
- The sensor's pixels and the quadrature rules of the image-formation integrals:
  [`SensorQuadrature`](@ref) on a pixel, [`ApertureQuadrature`](@ref) on the aperture.
- The scene's light: an [`EnvironmentLight`](@ref) of a
  [`SphericalHarmonicMap`](@ref).
- A surface's reflectance: [`Material`](@ref), a spatially varying Cook–Torrance
  BSDF with a GGX microfacet distribution.
- A printed planar target: [`TexturedTarget`](@ref), a posed planar target of
  VisualGeometryToolkitCore with its texture, its printed edge and its own state
  ([`TargetState`](@ref): its warping, its printed edge, its in-plane print error).
"""
module VisualRadiometryToolkitCore

using StaticArrays: SVector, SMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, I, cross, dot, norm, normalize
using Adapt: Adapt, adapt   # a textured target's arrays move to a device (scene/textured_target.jl)
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
import VisualGeometryToolkitCore as VgtkCore   # the spline system of a focus surface, reached qualified (camera/focus.jl)
# VisualGeometryToolkitCore's contract generics these types answer: a field's centre and element type, the support
# protocol of a surface's control points, the parameter protocol, a light's units
import VisualGeometryToolkitCore: center, centroid, convert_eltype, support_trait, nodes, support,
    parameter_vector, parameter_names, with_parameters, has_units, with_unit,
    project, backproject,   # a radiometric camera's geometric maps, forwarded to its geometric camera; `backproject(camera, 𝐩, 𝐚)`, the radiometric back-projection
    chart,                  # a textured target's page chart of a world point
    lens                    # refused by name on a radiometric camera (its geometric camera's lens model is `lens(geometric(camera))`)

export AbstractVignetting, NoVignetting, TensorProductVignetting, RadialVignetting, LogVignetting   # a camera's vignetting (camera/vignetting.jl)
public log_spline        # a LogVignetting's spline of log V
public VIGNETTING_TAGS   # the fields' TagRegistry: the `type` of VisualRadiometryToolkitIO's vignetting body
export fit_vignetting   # a field fitted to a function of the sensor position (camera/vignetting.jl)
public coefficient_jacobian, active_coefficients, control_points, with_control_points, n_control_points, knot_vectors, spline_degree,
       field_radius, radial_coordinate, pole_regular_basis   # the fields' basis, accessors and a radial profile's regular subspace
public RADIAL_CHARTS, BinnedRadialProfile, projective_chart, projective_knots, radial_chart, with_center, center_gradient   # a radial profile's chart and centre; a measured profile
export EnvironmentLight, SphericalHarmonicMap   # the scene's light: radiance from every direction on a sphere about a centre, in real SH (scene/lights.jl)
public radiance, exit_direction, radiance_map, coefficients, with_coefficients, max_degree, sh_basis, sh_count, sh_index   # its evaluation, accessors and the SH basis

export RadiometricCameraModel   # the radiometric camera: a geometric camera with its focus surface, aperture radius and vignetting (camera/radiometric_camera.jl)
export with_vignetting   # a radiometric camera's vignetting replaced: the start of a calibration
public geometric, focus, aperture_radius, with_geometric, with_focus, with_aperture_radius   # its parts and their replacers
public chief_ray, chief_direction, center_of_projection, focus_point, aperture_direction, world_ray   # its camera-frame maps: the chief ray, the focus point, the back-projection from the aperture on the camera's parts (a camera's is `backproject(camera, 𝐩, 𝐚)`), a ray in the world
public 𝔭, 𝔣, π̂⁻¹   # the paper's notation: aliases of center_of_projection, focus_point and VisualGeometryToolkitCore's backproject
public Focus, FocusSpline, n_nodes, inverse_focus_distance, focus_distance   # the focus surface: the inverse focus distance as a thin plate spline, and its host-side solver (camera/focus.jl)
public t̂, 𝔱   # the paper's notation: aliases of inverse_focus_distance and focus_distance
public sensor_position, pixel_position, pixel_footprint, luma, luma_image   # the sensor domain: Julia's pixel indices and sensor positions, a pixel's footprint, luma (sensor/notation.jl)
public 𝐩_of_pixel, pixel_of_𝐩, ℐ_𝐮   # the paper's notation: aliases of sensor_position, pixel_position and pixel_footprint
public SensorQuadrature, ApertureQuadrature, sensor_samples, aperture_samples, aperture_border, sensor_sample, aperture_sample,
       aperture_weight, aperture_border_sample, n_disc, n_border   # the rules on a pixel and on the aperture disc and its border (sensor/quadrature.jl)
public 𝐩_sample, 𝐚_sample, 𝐚_weight, 𝐚_border   # the paper's notation: aliases of sensor_sample, aperture_sample, aperture_weight and aperture_border_sample
export Material   # a surface's reflectance
public diffuse_weight, nonlinear_parameters, with_nonlinear, with_diffuse_weight, texture_weight, roughness, refractive_index,
       ggx_distribution, ggx_lambda, ggx_masking, ggx_masking_shadowing, fresnel_dielectric, sample_visible_normal,
       visible_normal_density, reflection_pdf, reflect, cook_torrance_terms, cook_torrance   # a surface's reflectance: the Cook–Torrance BSDF and its GGX pieces (scene/materials.jl)
public Θ_m_nonlinear, with_μ, 𝛂, 𝛈, Λ_ggx   # the paper's notation: aliases of nonlinear_parameters, with_diffuse_weight, roughness, refractive_index and ggx_lambda
export TexturedTarget   # a printed planar target: VisualGeometryToolkitCore's posed target with its texture, printed edge and state (scene/textured_target.jl)
public TargetState, with_state, with_h, with_edge, with_inplane, height_on, inplane_on, ink_spread, print_blur,
       EDGE_NC, HEIGHT_NC, HEIGHT_NODES, INPLANE_NC   # the target's own state: its warping, its printed edge, its in-plane print error (scene/target_state.jl)
public with_sdf, with_facing, has_sdf, posed_target, board_normal, world_point, corners, texture_size, intersect_board, board_plane_hit,
       inside, albedo, printed_albedo, edge_albedo   # its geometry (the page, its chart, a ray's hit) and its appearance (the texture, the printed edge)
public 𝔟, ρ_c   # the paper's notation: aliases of VisualGeometryToolkitCore's centroid (a target's centre) and albedo
public warping_nodes, warping_aspect, warping_field, flat_surface, board_height, board_relief, is_warped, BoardRays,
       inplane_calibration, placed_chart, page_fraction, design_chart, physical_chart, page_points   # its warping and in-plane print error on the state (scene/target_warping.jl)
public CONTRACT_GENERICS   # the functions another package may add methods to

# The sensor ------------------------------------------------------------------
include("sensor/notation.jl")          # sensor positions and Julia's pixels, a pixel's footprint, luma
include("sensor/quadrature.jl")        # the quadrature rules of the image-formation integrals

# The camera's parts ---------------------------------------------------------
include("camera/vignetting.jl")        # the vignetting fields and their protocol; NoVignetting, the absent one
include("camera/focus.jl")             # the focus surface and its host-side solver
include("camera/radiometric_camera.jl") # the radiometric camera and its back-projection from the aperture

# The scene's light -----------------------------------------------------------
include("scene/lights.jl")             # EnvironmentLight, SphericalHarmonicMap, sh_basis (extends vignetting.jl's coefficient_jacobian)
include("scene/materials.jl")          # Material: the spatially varying Cook–Torrance BSDF

# The printed target -----------------------------------------------------------
include("scene/target_state.jl")       # TargetState: a textured target's warping, printed edge and in-plane print error, by value
include("scene/textured_target.jl")    # TexturedTarget: VisualGeometryToolkitCore's posed planar target with its texture and state
include("scene/target_warping.jl")     # the warped page (Core's HeightField, MappedSurface) and the in-plane print error on the state
include("scene/printed_edge.jl")       # the printed-edge model of a target with a distance map

"""
    CONTRACT_GENERICS

The generic functions of VisualRadiometryToolkitCore another package may add
methods to across a package boundary (VisualGeometryToolkitCore's
`contract_generic_violations` reads this tuple):

- [`chief_ray`](@ref): a geometric camera type of another package answers it to
  carry a radiometric camera;
- the camera-frame maps a record holding a radiometric camera's parts forwards
  to their one implementation: [`chief_direction`](@ref), [`inverse_focus_distance`](@ref),
  [`focus_point`](@ref), [`world_ray`](@ref) (the radiometric back-projection such a record answers is
  VisualGeometryToolkitCore's contract generic `backproject`, with the aperture point as a third argument);
- the part accessors such a record answers: [`geometric`](@ref), [`focus`](@ref),
  [`aperture_radius`](@ref).
"""
const CONTRACT_GENERICS = (chief_ray, chief_direction, inverse_focus_distance, focus_point, world_ray, geometric, focus, aperture_radius)

end # module

# VisualRadiometryToolkitCore changelog

## 0.1.1

Compat only: on VisualGeometryToolkitCore 0.13 (`[compat]` `"0.13"`), the release that adds the artifact store and
removes the spherical spline and the dilogarithm, which this package does not use. No code changed.

## 0.1.0

The first release. The package holds the types of a radiometric camera and of
the scene it sees. They came from two places: the vignetting fields, the
measured radial profile and the scene's light from VisualGeometryToolkitCore
(its 0.11 and earlier held them; its 0.12.0 refuses each name and names this
package), and the radiometric camera, the focus surface, the quadrature rules,
the material and the textured target from RadiometricCamera (the code of the
paper "Real Cameras are Radiometric"). It depends on VisualGeometryToolkitCore
0.12.

### Added

- From VisualGeometryToolkitCore, with the same names and behaviour: the
  vignetting fields (`AbstractVignetting`, `TensorProductVignetting`,
  `RadialVignetting`, `LogVignetting`, `log_spline`, `VIGNETTING_TAGS`, and
  their verbs `coefficient_jacobian`, `active_coefficients`, `control_points`,
  `with_control_points`, `n_control_points`, `knot_vectors`, `spline_degree`,
  `field_radius`, `radial_coordinate`, `radial_chart`, `RADIAL_CHARTS`,
  `projective_chart`, `projective_knots`, `with_center`, `center_gradient`,
  `pole_regular_basis`); the measured radial profile (`BinnedRadialProfile`);
  the scene's light (`EnvironmentLight`, `SphericalHarmonicMap`, `radiance`,
  `exit_direction`, `radiance_map`, `coefficients`, `with_coefficients`,
  `max_degree`, `sh_basis`, `sh_count`, `sh_index`). Migration from
  VisualGeometryToolkitCore 0.11: import the names from this package; nothing
  else changes. The types answer VisualGeometryToolkitCore's contract generics
  (`center`, `convert_eltype`, the support protocol, the parameter protocol,
  the units of a light).
- `NoVignetting`: the absent vignetting, `V ≡ 1`. A singleton with no
  parameters (no calibration coordinates, no Jacobian columns) whose value is
  `true`, the identity of the product it enters. It subtypes
  `AbstractVignetting` and answers the parameter protocol with nothing.
- From RadiometricCamera (its commit 247c089), under descriptive names (listed
  below): the radiometric camera `RadiometricCameraModel` (its composed constructor,
  `geometric`, `focus`, `aperture_radius` and their `with_…` replacers, the
  forwards of `project` and `backproject`) and its camera-frame maps
  (`chief_direction`, `focus_point`, `inverse_focus_distance`, `world_ray`,
  `center_of_projection`); the focus surface (`Focus`, `FocusSpline`,
  `n_nodes`, `focus_distance`), a thin plate spline over the sensor; the
  sensor domain
  (`sensor_position`, `pixel_position`, `pixel_footprint`, `luma`,
  `luma_image`) and the quadrature
  rules (`SensorQuadrature`, `ApertureQuadrature` and their samples); the
  material (`Material` and the Cook–Torrance / GGX functions).
- From RadiometricCamera (its commit ae436a4): the textured target. Its
  `PrintedTarget` is `TexturedTarget` here — VisualGeometryToolkitCore's posed
  planar target with its texture, the optional distance map of the printed
  layout and the page chart (`chart`, `world_point`, `corners`,
  `intersect_board`, `board_plane_hit`, `board_normal`, `inside`,
  `texture_size`, `with_sdf`, `has_sdf`); `ρ_c` is `albedo` and `𝔟` is
  `target_center` (the paper's symbols stay as public aliases); the
  printed-edge model (`edge_albedo`, and `printed_albedo`: the texture's or the
  printed edge's); the warping and the in-plane print error (`HEIGHT_NC`,
  `HEIGHT_NODES`, `INPLANE_NC`, `EDGE_NC`, `warping_nodes`, `warping_aspect`,
  `warping_field`, `flat_surface`, `board_height`, `board_relief`,
  `is_warped`, `BoardRays`, `inplane_calibration`, `placed_chart`,
  `page_fraction`, `design_chart`, `physical_chart`, `page_points`,
  `posed_target`), with the target's methods of `convert_eltype`, `chart` and
  Adapt's `adapt_structure`.
- `TargetState`: a textured target's own state — the nodal heights of its
  warping `h`, its printed edge `edge` (`ink_spread`, `print_blur`, mm) and its
  in-plane print error `inplane` — a field of the target (`state`), isbits and
  replaced by value (`with_state`, `with_h`, `with_edge`, `with_inplane`, on a
  state or on the target). It was RadiometricCamera's `BoardSurface`, held
  beside the target in its `Scene`; the functions that took the pair take the
  target (`edge_albedo(target, 𝐛)`, `BoardRays(target)`,
  `design_chart(target, 𝐛)`, `posed_target(target)`). There is no scene type.
- `chief_ray(geometric, 𝐩)`: the one function through which a geometric camera
  carries a radiometric camera (any VisualGeometryToolkitCore camera answers
  it), and `CONTRACT_GENERICS`, the functions another package may add methods
  to. Each camera-frame map has one implementation, on the parts it reads
  (`focus_point(geometric, focus, 𝐩)`, `aperture_direction(d̂, 𝐚, t̂)`,
  `world_ray(pose, 𝐚, d)`).
- The public names are descriptive ASCII; each symbol of the paper is a public
  alias bound to the same function (`𝔭`, `𝔣`, `π̂⁻¹`, `t̂`, `𝔱`, `𝐩_of_pixel`,
  `pixel_of_𝐩`, `ℐ_𝐮`, `𝐩_sample`, `𝐚_sample`, `𝐚_weight`, `𝐚_border`,
  `Θ_m_nonlinear`, `with_μ`, `𝛂`, `𝛈`, `Λ_ggx`). Against RadiometricCamera's
  names: `chief_dir` → `chief_direction`; `𝔭` → `center_of_projection`; `𝔣` →
  `focus_point`; `t̂` → `inverse_focus_distance` (of a focus surface at a sensor
  position, and of a camera);
  `𝔱` → `focus_distance`; `𝐩_of_pixel` → `sensor_position`; `pixel_of_𝐩` →
  `pixel_position`; `ℐ_𝐮` → `pixel_footprint`; `𝐩_sample` → `sensor_sample`;
  `𝐚_sample`, `𝐚_weight`, `𝐚_border` → `aperture_sample`, `aperture_weight`,
  `aperture_border_sample`; `Θ_m_nonlinear` → `nonlinear_parameters`; `with_μ`
  → `with_diffuse_weight`; `𝛂`, `𝛈` → `roughness`, `refractive_index`; `D_ggx`,
  `Λ_ggx`, `G1_ggx`, `G2_ggx` → `ggx_distribution`, `ggx_lambda`,
  `ggx_masking`, `ggx_masking_shadowing`; `F_dielectric` →
  `fresnel_dielectric`; `sample_vndf_caps` → `sample_visible_normal`; `D_v` →
  `visible_normal_density`; `PDF_reflect` → `reflection_pdf`; `f_CT_parts`,
  `f_CT` → `cook_torrance_terms`, `cook_torrance`. `Material`'s fields and
  keywords are `roughness_ink`, `roughness_paper`, `refractive_index_ink`,
  `refractive_index_paper`, `diffuse_weight`.
- The radiometric back-projection of a camera is a method of
  VisualGeometryToolkitCore's `backproject`, the aperture point its third
  argument: `backproject(camera, 𝐩, 𝐚)` (the paper's `π̂⁻¹`, an alias of
  `backproject`). On a camera's parts it is `aperture_direction`.
- The focus surface is the thin plate spline over the sensor, and a camera's
  inverse focus distance at 𝐩 is that spline at 𝐩. RadiometricCamera's
  experimental focus surfaces on the chief directions (a thin plate spline in
  the azimuthal-equidistant chart, a spherical spline) are not taken:
  `Focus` has no `kind`, and `FocusSpline(nodes, kind)`,
  `inverse_focus_distance(focus, direction)`, `focus_weights` and
  `polar_cap_nodes` are refused by name (`FOCUS_SENSOR`,
  `FOCUS_DIRECTION_CHART`, `FOCUS_SPHERE`, `ae_chart` and `ae_dir` are not
  names of this package). The nodal weights of a focus surface at a sensor
  position are VisualGeometryToolkitCore's `nodal_weights` of
  `FocusSpline(focus).sys`.
- `lens(camera::RadiometricCameraModel)` is refused by name: `lens` is
  VisualGeometryToolkitCore's lens model of a geometric camera, a radiometric
  camera's is `lens(geometric(camera))`.
- `RadiometricCameraModel(geometric; focus, aperture_radius)` has
  `NoVignetting()` unless a vignetting is stated (in RadiometricCamera the
  default was a flat 4 × 4 surface, the start of its calibration: that start is
  asked for there, by name).

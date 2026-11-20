# VisualRadiometryToolkitCore changelog

## 0.0.1 (placeholder, not registered)

The package skeleton.

### Added

- `NoVignetting`: the absent vignetting, `V ≡ 1`. A singleton with no
  parameters (no calibration coordinates, no Jacobian columns) whose value is
  `true`, so a kernel that multiplies by it is compiled to one that does not.
  It subtypes VisualGeometryToolkitCore's `AbstractVignetting` and answers its
  parameter protocol with nothing.
- From RadiometricCamera (its commit 247c089), under descriptive names (the
  next entry): the
  radiometric camera `RadiometricCameraModel` (its composed constructor,
  `geometric`, `focus`, `aperture_radius` and their `with_…` replacers, the
  forwards of `project` and `backproject`) and its camera-frame maps
  (`chief_direction`, `focus_point`, `inverse_focus_distance`, `world_ray`,
  `center_of_projection`); the focus surface (`Focus`, `FocusSpline`,
  `n_nodes`, `focus_distance`) and its kinds on the chief directions
  (`focus_weights`, `polar_cap_nodes`, `FOCUS_SENSOR`,
  `FOCUS_DIRECTION_CHART`, `FOCUS_SPHERE`); the sensor domain
  (`sensor_position`, `pixel_position`, `pixel_footprint`, `luma`,
  `luma_image`) and the quadrature
  rules (`SensorQuadrature`, `ApertureQuadrature` and their samples); the
  material (`Material` and the Cook–Torrance / GGX functions).
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
  position or at a unit chief direction, which was `t̂_dir`, and of a camera);
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
- The azimuthal-equidistant chart of a focus surface on the chief directions is
  VisualGeometryToolkitCore's equidistant lens, called directly
  (`project(Lens(Equidistant()), d)`, `backproject` its inverse): `ae_chart`
  and `ae_dir` are not names of this package.
- `lens(camera::RadiometricCameraModel)` is refused by name: `lens` is
  VisualGeometryToolkitCore's lens model of a geometric camera, a radiometric
  camera's is `lens(geometric(camera))`.

### Changed

- `RadiometricCameraModel(geometric; focus, aperture_radius)` has
  `NoVignetting()` unless a vignetting is stated (in RadiometricCamera the
  default was a flat 4 × 4 surface, the start of its calibration: that start is
  asked for there, by name).

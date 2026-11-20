# VisualRadiometryToolkitCore changelog

## 0.0.1 (placeholder, not registered)

The package skeleton.

### Added

- `NoVignetting`: the absent vignetting, `V ≡ 1`. A singleton with no
  parameters (no calibration coordinates, no Jacobian columns) whose value is
  `true`, so a kernel that multiplies by it is compiled to one that does not.
  It subtypes VisualGeometryToolkitCore's `AbstractVignetting` and answers its
  parameter protocol with nothing.
- From RadiometricCamera (its commit 247c089), under the same names: the
  radiometric camera `RadiometricCameraModel` (its composed constructor,
  `geometric`, `focus`, `aperture_radius` and their `with_…` replacers, the
  forwards of `project` and `backproject`) and its camera-frame maps
  (`chief_dir`, `𝔣`, `t̂`, `π̂⁻¹`, `world_ray`, `𝔭`); the focus surface (`Focus`,
  `FocusSpline`, `n_nodes`, `t̂`, `𝔱`) and its kinds on the chief directions
  (`ae_chart`, `ae_dir`, `t̂_dir`, `focus_weights`, `polar_cap_nodes`,
  `FOCUS_SENSOR`, `FOCUS_DIRECTION_CHART`, `FOCUS_SPHERE`); the sensor domain
  (`𝐩_of_pixel`, `pixel_of_𝐩`, `ℐ_𝐮`, `luma`, `luma_image`) and the quadrature
  rules (`SensorQuadrature`, `ApertureQuadrature` and their samples); the
  material (`Material` and the Cook–Torrance / GGX functions).
- `chief_ray(geometric, 𝐩)`: the one function through which a geometric camera
  carries a radiometric camera (any VisualGeometryToolkitCore camera answers
  it), and `CONTRACT_GENERICS`, the functions another package may add methods
  to. Each camera-frame map has one implementation, on the parts it reads
  (`𝔣(geometric, focus, 𝐩)`, `π̂⁻¹(d̂, 𝐚, t̂)`, `world_ray(pose, 𝐚, d)`).

### Changed

- `RadiometricCameraModel(geometric; focus, aperture_radius)` has
  `NoVignetting()` unless a vignetting is stated (in RadiometricCamera the
  default was a flat 4 × 4 surface, the start of its calibration: that start is
  asked for there, by name).

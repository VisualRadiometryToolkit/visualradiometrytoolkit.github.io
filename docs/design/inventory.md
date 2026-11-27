# Inventory: what moved into the Visual Radiometry Toolkit, and from where

The record of the migration of 2026-11-20/21 that created this toolkit's first
release (VisualRadiometryToolkitCore 0.1.0, VisualRadiometryToolkitIO 0.1.0).
Radiometry lifts geometry: the Visual Radiometry Toolkit depends on the Visual
Geometry Toolkit, never the reverse. Zero duplication: every item below exists
in exactly one package; where it left a package, that package refuses the name
by name with its replacement, and no `DUPLICATION.toml` holds an exception.

The placement rule for an ambiguous item: generic radiometry → here; the
calibration method of *Real Cameras are Radiometric* → RadiometricCamera.

## From VisualGeometryToolkitCore (≤ 0.11) → VisualRadiometryToolkitCore

| item | here |
|---|---|
| `AbstractVignetting`, `TensorProductVignetting`, `RadialVignetting`, `LogVignetting`, `log_spline`, `VIGNETTING_TAGS`, the fields' verbs (`coefficient_jacobian`, `active_coefficients`, `control_points`, `with_control_points`, `n_control_points`, `knot_vectors`, `spline_degree`, `field_radius`, `radial_coordinate`, `pole_regular_basis`, `with_center`, `center_gradient`), the radial charts (`RADIAL_CHART_TAGS`, `radial_chart`, `projective_chart`, `projective_knots`) | `src/camera/vignetting.jl` |
| `BinnedRadialProfile` (a measured radial profile; it shares the charts) | `src/camera/vignetting.jl` |
| `EnvironmentLight`, `SphericalHarmonicMap`, `radiance`, `exit_direction`, `radiance_map`, `coefficients`, `with_coefficients`, `max_degree`, `sh_basis`, `sh_count`, `sh_index` | `src/scene/lights.jl` |

Born here: `NoVignetting` (V ≡ 1, no control points, no parameters; the
default vignetting of a radiometric camera).

VisualGeometryToolkitCore 0.12.0 refuses each moved name (`src/retired.jl`,
`MOVED_NAMES`). It keeps the B-spline basis and knots, the support protocol,
the thin plate spline, the quadrature rules, the parameter protocol, the units,
`GaussianBlur`, RAW reading and the sensor's noise model (its feature detectors
use them). For this move it made public: `primal_value`, `strip_pixels`,
`strip_point`, `attach_point`, `attach_length`, `parameter_offsets`,
`MOVED_NAMES`; `center`, `has_units`, `with_unit` became contract generics.

## From VisualGeometryToolkitIO (≤ 0.10) → VisualRadiometryToolkitIO

The kinds `vgio/vignetting`, `vgio/environment_light` and `vgio/radial_profile`,
with their earlier versions' steps, JSON Schemas, fixtures and tests. The schema
names are unchanged, so files written before the move load as they are;
`load` and `save` are the same calls (methods of VisualGeometryToolkitIO's two
verbs). VisualGeometryToolkitIO 0.11.0 refuses a file of a moved kind by name
with its owner and has a public hook for a kind another package owns
(`KindSpec`, `write_kind`, `read_kind`, the spec combinators, `body_spec`,
`migrate_file`, `migrate_body`, `matrix_rows`, `rows_matrix`, `renamed_key`,
`length_unit`, …).

The panorama kind (`vgio/panorama`, `save_panorama`, `load_panorama`) went to
PanoramaStitching, the application whose result it is: a thin record whose
parts are serialized by their owners (camera, rotations and fit by
VisualGeometryToolkitIO; the vignetting by VisualRadiometryToolkitIO).

## From RadiometricCamera → VisualRadiometryToolkitCore

| item | here |
|---|---|
| `RadiometricCameraModel` (a geometric camera of VisualGeometryToolkitCore with a focus surface, an aperture radius and a vignetting), its composed constructor, accessors and replacers, and the camera-frame maps: `chief_ray`, `chief_direction`, `focus_point`, `inverse_focus_distance`, `backproject(camera, p, a)` (from an aperture point), `aperture_direction`, `world_ray`, `center_of_projection` | `src/camera/radiometric_camera.jl` |
| `Focus`, `FocusSpline` (the inverse focus distance as a thin plate spline over the sensor), `n_nodes`, `focus_distance` | `src/camera/focus.jl` |
| The sensor domain and the quadrature of the image-formation integrals: `sensor_position`, `pixel_position`, `pixel_footprint`, `luma`, `luma_image`, `SensorQuadrature`, `ApertureQuadrature` and their samples | `src/sensor/` |
| `Material` and the Cook–Torrance reflectance with its GGX pieces | `src/scene/materials.jl` |
| `TexturedTarget` (RadiometricCamera's printed target: a posed planar target of VisualGeometryToolkitCore with its texture), its state `TargetState` (warping heights, printed edge, in-plane print error), the printed-edge model, the target's charts and intersection | `src/scene/` |

The public names are descriptive ASCII. Until 0.2.0 the paper's symbols (`𝔣`,
`t̂`, `π̂⁻¹`, `𝔭`, `ρ_c`, `𝔟`, …) were constants bound to the same functions; they
are deleted (one name per thing), and the paper's symbol map lives in the paper.

Stays in RadiometricCamera (the paper's calibration method): the kernels'
`View`, the flux and device kernels, the Monte-Carlo radiance sampler, the
vignetting rules and gauge, the focus start, `TargetRadiometry`,
`RadiometricTarget`, the observation model, `CalibrationState`, the LM blocks,
the pipeline, options, diagnostics and records. RadiometricCamera's `Scene` was
dissolved, not moved: the image size is the camera's, the surface parameters
are the textured target's state.

## Decisions taken on the way

- No general scene type in either toolkit (deferred until a second user
  exists; "scene" also names dataset scenes in VisualGeometryToolkitEval).
- The focus surface is the sensor-grid thin plate spline only: the
  alternative parameterisations of an experiment were deleted, not moved.
- A SplineLens camera's chief ray (its backward spline's value) lives beside
  the generic `chief_ray` here: a method on another package's type for this
  package's function belongs to the function's owner.
- VisualGeometryToolkitCore's `SphericalSplineSystem`, `spherical_spline_kernel`,
  `spherical_spline_coefficients`, `spherical_spline_evaluate` and `dilog` have
  no user in the stack after this migration and leave in its next minor.
- Dependants: RadiometricCamera and PanoramaStitching were ported to this
  toolkit; BlobBoards, LocalOptimizationDoneRight and RANSACScoringDoneRight
  use none of the moved items and only widened their compat.

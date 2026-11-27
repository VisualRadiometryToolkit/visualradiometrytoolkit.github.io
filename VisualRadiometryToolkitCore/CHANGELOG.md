# VisualRadiometryToolkitCore changelog

## 0.2.0 (unreleased)

One release of three lines: the physical forms (a board posed in the world, a camera's lengths, the light about its
board, a light's terms by `(l, m)`), the anchored albedo with Smith Λ without cancellation, and the stack's
conformance on VisualGeometryToolkitCore 0.14 (`[compat]` `"0.14"`, the release that moves estimation to
`solve(problem, algorithm)`; this package's one estimator is the closed form `VignettingLeastSquares`): one name per thing, type arguments positional, the
radial chart a type. Float64 values move only by the Λ rewrite's rounding.

### Breaking

- `TexturedTarget` takes no `facing` keyword (both constructors). The board faces the side its cameras are on:
  `with_facing(board, viewpoint)` orients it, and a camera's state or render does so by its pose; until then it faces the
  design's +z, the printed side of the design chart (the former default without `facing` was the other side).
- `target_center` is removed: a target's centre is VisualGeometryToolkitCore's `centroid(board)`.
- **The paper's notation aliases are deleted** (one name per thing: no alias, no `const` rebinding). Each name is its
  function's: `𝔭` → `center_of_projection`, `𝔣` → `focus_point`, `π̂⁻¹` → VisualGeometryToolkitCore's `backproject`
  (its radiometric method, `backproject(camera, 𝐩, 𝐚)`), `t̂` → `inverse_focus_distance`, `𝔱` → `focus_distance`,
  `𝐩_of_pixel` → `sensor_position`, `pixel_of_𝐩` → `pixel_position`, `ℐ_𝐮` → `pixel_footprint`, `𝐩_sample` →
  `sensor_sample`, `𝐚_sample` → `aperture_sample`, `𝐚_weight` → `aperture_weight`, `𝐚_border` →
  `aperture_border_sample`, `Θ_m_nonlinear` → `nonlinear_parameters`, `with_μ` → `with_diffuse_weight`, `𝛂` →
  `roughness`, `𝛈` → `refractive_index`, `Λ_ggx` → `ggx_lambda`, `𝔟` → VisualGeometryToolkitCore's `centroid`, `ρ_c` → `albedo`. The
  symbols stay the paper's notation in prose; the manual's notation table is gone with them.
- **A type argument is positional** (the stack's signature rule: slot 4, never a keyword): `Focus(n, distance, W, H;
  T)` → `Focus([T = Float64,] n, distance, W, H)`, `Focus(geometric, distance; n, T)` → `Focus([T,] geometric,
  distance; n)`, `TensorProductVignetting(n, box; degree, T)` → `TensorProductVignetting([T,] n, box; degree)`,
  `RadialVignetting(n, center, radius; degree, T, chart)` → `RadialVignetting([T,] n, center, radius; degree,
  chart)`, `TexturedTarget(target, texture; …, T)` → `TexturedTarget([T,] target, texture; …)`.
- **The radial chart is a type, not a Symbol**: `LinearChart()`, `ProjectiveChart()`, `EquisolidChart()` (new,
  `public`, under `AbstractRadialChart`; the types the profiles already held privately as their chart parameter).
  `chart = :projective` → `chart = ProjectiveChart()`; `BinnedRadialProfile(:equisolid, …)` →
  `BinnedRadialProfile(EquisolidChart(), …)`; `radial_chart(v)` returns the chart value (`ProjectiveChart()`), not
  a Symbol. `RADIAL_CHARTS` (a tuple of Symbols) is replaced by the `TagRegistry` `RADIAL_CHART_TAGS` (`"linear"`,
  `"projective"`, `"equisolid"`: the stored spellings, unchanged). A chart that is not one is the keyword's
  `TypeError`; `EquisolidChart()` for a fitted profile stays an `ArgumentError`.

### Added

- `TexturedTarget(target::PosedTarget, texture)` of a target with no canvas: the texture covers its board (a bare board posed
  in the world). A physical (unitful) posed target is taken in metres at entry.
- `with_facing(board, viewpoint)`.
- `RadiometricCameraModel(geometric; focus, aperture_radius)` and `Focus([T,] geometric, distance; n)` take lengths (`1.5m`, `2mm`);
  plain numbers stay metres. `f_number = N` states the aperture as the photographer's stop instead: r = f / 2N, f the camera's
  focal length as a length (VisualGeometryToolkitCore 0.13.3's `metric_focal_length`, a camera bounded by its sensor).
  VisualGeometryToolkitCore compat `"0.13.3"`.
- `EnvironmentLight(map, board::TexturedTarget, poses)`: the light on the sphere about the board's centre that holds every
  camera centre and every corner of the page.
- `SphericalHarmonicMap(l_max, (l, m) => values, …)` and `coefficients(map_or_light, l, m)`.
- `RadialVignetting([T,] n, geometric; degree, chart)`: the flat radial profile about a camera's principal point out to the farthest point it
  images.
- `diffuse_weight(material)`. `Material` and `with_vignetting` are exported.
- `VignettingLeastSquares(; samples = 33)`, exported: the closed form (VisualGeometryToolkitCore's `ClosedFormKind`) that
  fits a field's control points to a function of the sensor position, `solve(EstimationProblem(typeof(field), (f,
  field)), VignettingLeastSquares(; samples))`, its `u` the fitted field and `n` the samples. It replaces the internal
  least squares of the same numerics that tests reached by its private name.
- `physical_albedo(target, 𝐛)`: the albedo of the target as printed at the
  physical page chart 𝐛, `printed_albedo` at the design point that 𝐛 shows
  under the in-plane print error (`design_chart`). It is what a renderer reads
  at a ray's hit.
- `anchored_albedo(target, 𝐱₀, δ𝐱)`: `physical_albedo` at the surface point
  `𝐱₀ + δ𝐱`, given as an anchor (a hit found once in Float64) and an offset (a
  kernel's Float32 numbers, its duals). The chart, the design chart and the
  map's read run in the anchor's precision, and the result is in the offset's
  numbers. A Float32 world point a metre from the origin is ≈ 0.06 µm coarse,
  and on a printed edge with a 0.03 mm blur that moves the slope by about 1 %.
  The page and its maps are in the anchor's float, the state in any numbers.
- `ggx_lambda(α, ω)`, `ggx_masking(α, ω)`, `ggx_masking_shadowing(α, ω, ω′)`
  of the directions themselves (the cosine forms stay).

### Changed

- The sensor notation's footprint comment names `sensor_position(u, v)`, not the retired alias `𝐩_of_pixel` (Core 0.14's
  RETIRED_NAMES); docs/design/inventory.md names `RADIAL_CHART_TAGS`. No code change.
- Smith Λ without cancellation: `tan²θ` from the direction's components (from
  a Float32 cosine, `1 − cos²θ` loses the small angles: 0.2 % of tan²θ at
  θ = 0.005) and `x / (2(1 + √(1 + x)))` for `√(1 + x) − 1`.
  `visible_normal_density` and `cook_torrance_terms` take Λ of their
  directions. Float64 values move by rounding only.
- The part replacers (`with_geometric`, `with_focus`, `with_aperture_radius`, `with_vignetting`) and a textured
  target's `with_state` replace their field with Accessors' `@set`, the stack's one idiom for a value with one part
  replaced, instead of each restating its type's constructor (VisualGeometryToolkitCore 0.14's duplication gate
  found `with_vignetting` and `with_state` to be one body). New dependency: Accessors.
- The README's and the manual's example builds its pinhole camera as `Lens(Perspective())`: VisualGeometryToolkitCore
  0.14 removed the alias `Pinhole`.

## 0.1.1

Compat only: on VisualGeometryToolkitCore 0.13 (`[compat]` `"0.13"`), the release that adds the artifact store and
removes the spherical spline and the dilogarithm, which this package does not use. No source changed; a test reads
an ArgumentError's message through VisualGeometryToolkitCore's `thrown_message`, no copy of its own.

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

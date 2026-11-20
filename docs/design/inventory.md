# Inventory and migration design

What moves into this workspace, from where, who depends on it, the type
hierarchy it lands in, and the order of the moves.

Sources read (2026-11-20): VisualGeometryToolkitCore 0.11.1 and
VisualGeometryToolkitIO 0.10.6 (the
[VisualGeometryToolkit.jl](https://github.com/VisualGeometryToolkit/VisualGeometryToolkit.jl)
monorepo), RadiometricCamera 0.1.0
([realcamerasareradiometric.github.io](https://github.com/RealCamerasAreRadiometric/realcamerasareradiometric.github.io),
branch `perf/optimize-and-compose`), PanoramaStitching 0.5.1, BlobBoards.
Names and paths are as read from source text; nothing was run. Both source
repositories were being edited while they were read, so line-level facts can
have moved.

Abbreviations: **VGTK** = Visual Geometry Toolkit, **VRTK** = Visual Radiometry
Toolkit (this workspace), **RC** = RadiometricCamera.

## 1. The rule

Radiometry lifts geometry. A package of VRTK may depend on VGTK packages; no
VGTK package depends on a VRTK package.

| destination | what belongs there |
|---|---|
| **VRTK Core** (`VisualRadiometryToolkitCore`) | the types of a radiometric camera and scene, and the kernels that evaluate them |
| **VRTK IO** (`VisualRadiometryToolkitIO`) | the file kinds of those types, in VGTK IO's envelope |
| **VRTK Estimation** (a later package) | calibrating a radiometric camera: residuals, Jacobians, parameter blocks, starts, solves |
| **stays in VGTK** | geometry, and what geometry's own code needs: RAW reading, the sensor noise model, capture settings, generic numerics |
| **stays in RC** | the paper's pipeline, experiments, options, records and command line |

## 2. What is in VisualGeometryToolkitCore today

No camera, capture, target or rig type of VGTK Core holds a radiometric field.
The radiometric code is three files under `src/geometry/cameras/`, all also
exported through the inner `Cameras` module.

### 2.1 Vignetting: `vignetting.jl` (587 lines) → VRTK Core

| name | kind | status in VGTK Core | what it is |
|---|---|---|---|
| `AbstractVignetting` | abstract type | exported | a vignetting field `V` on the sensor, linear in its control points; callable `v(u)` and `v(u, f)` |
| `TensorProductVignetting{T,NX,NY,KX,KY,NXY,DP,DQ}` | struct | exported | tensor-product B-spline surface over a sensor box: `knots_x`, `knots_y`, `P` |
| `RadialVignetting{T,N,K,DP,C}` | struct | exported | radial B-spline profile on a radial chart: `center`, `radius`, `knots`, `P` |
| `LogVignetting{S<:AbstractVignetting}` | struct | exported | `V = exp(s(u))` of a spline field `s`: `spline` |
| `BinnedRadialProfile{C}` | struct (no supertype) | public | a measured radial profile in bins: `center`, `radius`, `focal_length`, `edges`, `values`, `counts` |
| `RADIAL_CHARTS` | const | public | the registry of radial charts: `(:linear, :projective, :equisolid)` |
| `VIGNETTING_TAGS` | const (`TagRegistry`) | public | the `type` tag of the vignetting file body: `tensor_product`, `radial`, `log` |
| `coefficient_jacobian(v, u)` | function | public | `∂V/∂vec(P)` |
| `active_coefficients(v, u)` | function | public | the nonzero entries of that row |
| `control_points`, `n_control_points`, `with_control_points` | functions | public | the control points, their count, the field rebuilt from new ones |
| `knot_vectors`, `spline_degree` | functions | public | the spline's structure |
| `field_radius`, `radial_coordinate`, `radial_chart` | functions | public | the radial fields' geometry |
| `projective_chart`, `projective_knots` | functions | public | the projective radial chart and its knots |
| `with_center`, `center_gradient` | functions | public | a radial field recentred; `∂V/∂center` |
| `pole_regular_basis` | function | public | the basis of radial profiles that are regular at the centre |
| `log_spline` | function | public | the spline of a `LogVignetting` |

Methods it adds to generics that stay in VGTK Core: `center`, `convert_eltype`,
the support protocol (`support_trait`, `nodes`, `support`), the parameter
protocol (`parameter_vector`, `parameter_names`, `with_parameters`).

It uses, from VGTK Core: `bspline_basis`, `clamped_knots`, `HomographyMap`,
`TagRegistry`, `Rect2`, `LocalSupport` (public), and two internal helpers
(`_strip_pixels`, `_primal`).

### 2.2 Lights: `lighting.jl` (261 lines) → VRTK Core

| name | kind | status | what it is |
|---|---|---|---|
| `SphericalHarmonicMap{L,C,J,CJ,T}` | struct (no supertype) | exported | `C` channels of real spherical-harmonic coefficients to degree `L`; callable on a direction |
| `EnvironmentLight{M,T}` | struct (no supertype) | exported | radiance from every direction on a sphere about a centre: `map`, `center`, `radius` |
| `sh_count`, `sh_index`, `sh_basis` | functions | public | the real spherical-harmonic basis |
| `coefficients`, `max_degree`, `with_coefficients`, `radiance_map` | functions | public | accessors and rebuild |
| `exit_direction`, `radiance` | functions | public | the direction a ray leaves the sphere in; the radiance along it |
| `coefficient_jacobian(light, x, ω)` | method | public | `∂radiance/∂coefficients` (a method of vignetting's generic) |

There is no other light type and no abstract light type. Methods on staying
generics: `center`, `GeometryBasics.radius`, the parameter protocol,
`convert_eltype`, `has_units`, `ustrip`, `with_unit`. Internal helpers used:
`_primal`, `_ustrip_point`, `_attach_point`, `_attach_length`.

### 2.3 Blur: `blur.jl` (185 lines) → VRTK Core

| name | kind | status | what it is |
|---|---|---|---|
| `AbstractBlur` | abstract type | exported | a blur kernel of an imaging model on a plane |
| `GaussianBlur{C<:CovMat{2}}` | struct | exported | point-spread density `N(0, Σ)`; the covariance's frame is the plane |
| `convolve(a, b)` | function | public | the blur of two blurs in sequence |

It is built on VGTK Core's framed covariance (`CovMat`, `propagate`, `relabel`)
and four of its internals (`_FormStorage`, `_frame`, `_check_junction`,
`_parameter_offsets`). It is the item most tied to VGTK Core's types; it moves
last of the three (section 6).

### 2.4 What stays in VGTK Core

| item | why it stays |
|---|---|
| RAW reading: `RawMosaic`, `LinearRaw`, `BayerCellFrame`, `bayer_plane_map` (`src/raw/raw_mosaic.jl`, `linear_raw.jl`) | VisualGeometryToolkitFeatures' detectors read RAW photosites (`foerstner.jl`, `raw_green.jl`, `raw_image.jl`, `sfop.jl`, `image_circle.jl`, …) |
| the sensor NOISE model: `SensorModel`, `SensorCharacterisation`, `sensor_model`, `PoissonGaussian`, `photon_transfer`, `master_dark`, `defect_onsets` (`sensor_model.jl`, `sensor_estimators.jl`) | the same detectors weigh photosites by their variance (`variance_stabilization.jl`, `foerstner.jl`, `sfop.jl`) |
| capture settings: `CaptureSettings`, `ExposureSettings`, `LensSettings`, `FrameSettings`, `DeviceIdentity`, `is_constant` (`captures.jl`) | the noise model is resolved per frame from them, and Features' RAW reader names them |
| `image_circle`, `lens_coverage`, `farthest_radius` | where light falls on the sensor is geometry of the lens |
| `ChartSpline`, `equidistant_chart`, the support protocol | the spline lens uses them |
| numerics first written for RC and now generic: B-spline evaluation, thin-plate and spherical splines, `gauss_hermite_prob`, `hammersley`, the penalized least squares, `gpu_tier` | not radiometric; other packages use or can use them |

### 2.5 Where VGTK Core itself touches the moving code

These are the edits its retirement needs:

1. `src/precompile.jl`: the workload builds the three vignetting fields.
2. `blur.jl`: one method spans the three families,
   `local_coordinates(ch::ParameterManifold, x::Union{AbstractVignetting, EnvironmentLight, GaussianBlur})`.
3. `cameras.jl` and the main module: the includes and the export / public lists.
4. The naming checker's retired-name list (two entries on vignetting names).
5. Docstring cross-references into the moving files (`manifolds/subset.jl`,
   `base/types.jl`) and `docs/src/api/batched.md` (the sections Vignetting,
   Lighting, Blur).
6. Tests: `vignetting_tests.jl`, `radial_profile_tests.jl`, `lighting_tests.jl`,
   `blur_tests.jl`, a fixture directory, and one item of
   `downstream_hoists_tests.jl` (the parameter protocol of the three families).

No Makie or CUDA extension of VGTK Core uses a radiometric name.

## 3. What is in VisualGeometryToolkitIO today

| kind (current version) | type it holds | where it goes |
|---|---|---|
| `vgio/vignetting/v2.0` (v1 read) | `AbstractVignetting` (the three fields; body `type` from `VIGNETTING_TAGS`, radial `chart` from `RADIAL_CHARTS`) | **VRTK IO** |
| `vgio/environment_light/v2.0` (v1 read) | `EnvironmentLight{<:SphericalHarmonicMap}` | **VRTK IO** |
| `vgio/radial_profile/v1.0` | `BinnedRadialProfile` | **VRTK IO** |
| `vgio/blur/v2.0` | `Dict{Symbol, GaussianBlur}` | **VRTK IO**, with `GaussianBlur` |
| `vgio/panorama/v2.0` | a camera, rotations, an optional vignetting body, gains, a fit | **PanoramaStitching**, as a thin record over VRTK IO (the vignetting body) and VGTK IO (the rest) |
| `vgio/capture_settings/v2.0`, `vgio/sensor_characterisation/v2.0` | `CaptureSettings`, `SensorCharacterisation` | stay in VGTK IO |
| the envelope's `units.radiance` token (`"relative"`) | every kind's envelope | stays in VGTK IO (it is the envelope's) |

Files: `src/radiometry_schema.jl` (342 lines: the vignetting, environment-light
and blur kinds), `src/radial_profile_schema.jl` (85), `src/panorama_schema.jl`
(158), with entries in `validate.jl` (the kind table), `json_schema.jl` (the
vignetting body's schema), `migrate.jl` and `migrate_v010.jl` (the v1 → v2
steps of vignetting and environment light). Tests:
`radiometry_schema_tests.jl`, `radial_profile_schema_tests.jl`,
`panorama_schema_tests.jl`, items of `migrate_v010_tests.jl`,
`json_schema_tests.jl` and the envelope cases, and three fixtures of old
versions. Published JSON Schemas: `docs/src/schemas/vgio/{vignetting,
environment_light, blur, radial_profile, panorama}/`.

Two rules of VGTK IO govern the move:

- **A published file keeps loading.** A kind that moves keeps its name
  (`vgio/vignetting/…`), its bytes and its version steps; only the package
  that reads and writes it changes. The published `$id` of a schema is
  immutable, so the schema files already published stay where they are.
- **The envelope is VGTK IO's.** VRTK IO writes into it and validates through
  it; it registers its kinds with VGTK IO's validator and version steps and
  holds no copy of either. This needs VGTK IO to let another package register
  a kind (today the kind table is closed): the one enabling change on the
  VGTK side.

## 4. What is in RadiometricCamera today

RC has **no abstract type** for the camera, the focus, the aperture, the
material, the light or the target: every part is a concrete struct or a VGTK
Core type, and every part is mandatory. It has no sensor response layer at all.

### 4.1 → VRTK Core (the model and its evaluation)

| item | file (`src/`) | notes |
|---|---|---|
| `RadiometricCameraModel{L, F<:Focus, T<:Real, V<:AbstractVignetting}`: `geometric::L`, `focus::F`, `aperture_radius::T`, `vignetting::V`; `with_geometric`, `with_focus`, `with_aperture_radius`, `with_vignetting`; `geometric`, `focus`, `aperture_radius`; `project` / `backproject` forwarding to the geometric camera | `camera/radiometric_camera.jl` | the field `geometric` was named `lens` until this week; the rename is landing in RC now, and the type moves under the new name |
| `View{T,N,L,P}` (the single-eltype record a kernel takes: `pose`, `geometric`, `focus`, `r`), `chief_dir`, `𝔣`, `t̂`, `π̂⁻¹`, `world_ray`, `𝔭` | same | the vignetting is deliberately not in `View`: its Jacobian columns are analytic |
| the geometric-camera contract `_chief_ray`, `in_domain` and its methods for a bounded camera and a spline-lens camera | `camera/models/geometric.jl`, `pixel_camera.jl`, part of `grid_camera.jl` | to be stated on VGTK Core's `backproject` where it can be |
| `Focus{T,N}` (`nodes`, `t̂_i`, `w`, `a`, `kind`), `FocusSpline{N,S}`, `t̂(f, 𝐩)`, `𝔱`, `n_nodes` | `camera/focus.jl` | only the sensor thin-plate-spline surface moves; `kind` selects experiment variants by a run-time branch in the kernel today, and that branch does not move (section 5) |
| `SensorQuadrature{T,NS}`, `𝐩_sample`, `sensor_samples` | `sensor/quadrature.jl` | the pixel footprint's rule |
| `ApertureQuadrature{T,NA,NB}`, `𝐚_sample`, `𝐚_weight`, `𝐚_border`, `aperture_samples`, `aperture_border`, `n_disc`, `n_border` | same | the aperture disc's rule |
| the pixel-frame notation: `𝐩_of_pixel`, `pixel_of_𝐩`, `ℐ_𝐮`, `luma` | `sensor/notation.jl` | |
| `Material{T}` (`𝛂_ink`, `𝛂_noink`, `𝛈_ink`, `𝛈_noink`, `μ`), `Θ_m_nonlinear`, `with_nonlinear`, `with_μ`, `texture_weight` | `target/svbsdf.jl` | |
| the Cook–Torrance / GGX kernels: `D_ggx`, `Λ_ggx`, `G1_ggx`, `G2_ggx`, `F_dielectric`, `sample_vndf_caps`, `D_v`, `PDF_reflect`, `reflect`, `f_CT_parts`, `f_CT` | same | |
| `RadianceSampler`, `SampleKey`, `key_hash`, `draws`; `L_c` (the radiance leaving a surface point); `RadianceParts`, `radiance_parts`, `L_from_parts` | `image_formation/radiance.jl` | counter-based common random numbers |
| `RenderSettings{T,NS,NA,NB}` (`sensor`, `aperture`, `sampler`), `Φ_pixel` and the kernel body `_Φ_pixel` (value path), `pixel_id` | `image_formation/flux.jl` | the flux divides by `π r²`: a zero aperture is not representable today (section 5) |
| the value kernels and their launch: `_FluxAt`, `_MaskAt`, `compute_mask`, `masked_pixels`, `render_view`, the row-launch helpers | `image_formation/flux.jl`, `calibration/device/flux_kernels.jl`, `device/workers.jl` | isbits functors mapped by VGTK Core's `pointwise!`: one implementation, Float64 on the CPU and Float32 on a device |
| `convert_eltype` methods of the moved types | `calibration/precision.jl` | |

Open for the owner (section 8): the printed target's radiometric description
(`PrintedTarget`, `BoardSurface`, `Scene`, the warping field) is what the
kernel body takes as its scene today. It is specific to a printed board. It
either moves with the kernel or the kernel is first stated over a surface
contract and the printed target stays in RC.

### 4.2 → VRTK Estimation (later)

| concern | items |
|---|---|
| state and problem | `CalibrationState`, `PerViewResidual`, `PerTileResidual`, `build_problem`, `build_problem_grid`, the Jacobian layouts (`_jacobian_layout`, `_tile_layout`), `extract_variables`, `read_back!` |
| parameter blocks | `ApertureVar` (log radius), `MaterialVar`, `LightingVar`, `focus_block`, `lens_manifold`, `lens_free`, `lm_box`, `lm_scale` |
| Jacobian kernels | `_JacAt`, `_PartsAt`, `_PixelPartsAt`, `_RecordAt`, `_HeightAt`, the seed and record arguments of the kernel body, the device worker pool, the CUDA extension |
| closed-form solves | `PixelParts`, `RadiometryParts`, `solve_Θ_l!`, `solve_Θ_v!`, `solve_μ!`, `solve_radiometry_gn!`, `solve_linear_blocks!` |
| vignetting estimation | `vignetting_rule`, `vignetting_basis`, `gauge_basis`, `center_constraint`, `RadialSupportRule`, `tie_pole`, `vignetting_smoothness` |
| smoothness and weighting | `AbstractSmoothness` and its three subtypes, `Unweighted`, the row whitening |
| starts | `focus_start`, `start_grid`, the lattice rules, `thin_lens_focus_distance`, the start poses |

### 4.3 Stays in RC

The pipeline of the paper (`calibrate`, `start_calibration`,
`refine_calibration!`, `PipelineOptions` and the option tables, the TOML
configuration, the front ends), the photograph readers and the observation
bookkeeping (`ObservationModel`, `PhotoSet`), the run records and outputs, the
diagnostics, the command line (`bin/refine.jl`), the code its source marks as
experiments, and `experiments/` beside the package (the paper's runs).

## 5. The type hierarchy proposed for VRTK Core

A radiometric camera is a geometric camera and its **parts**. Each part is an
abstract type; each has an absent default named `No…`: a singleton with no
parameters (no calibration coordinates, no Jacobian columns) that is resolved
by dispatch at compile time. A camera built from a geometric camera alone has
every part absent and renders what that geometric camera renders.

```
AbstractVignetting                      attenuation across the sensor
├── NoVignetting                        V ≡ 1                     (born in VRTK Core; the camera's default)
├── TensorProductVignetting             ← VGTK Core
├── RadialVignetting                    ← VGTK Core
└── LogVignetting                       ← VGTK Core

AbstractAperture                        the opening that admits light
├── NoAperture                          a point: one ray per sensor sample, no division by an area
└── DiscAperture(radius)                ← RC's `aperture_radius` scalar, as a type

AbstractFocus                           where the camera is in focus
├── NoFocus                             everything in focus (the only focus a `NoAperture` camera needs)
└── Focus (thin-plate spline on the sensor)   ← RC, without its `kind` field

AbstractBlur                            the point spread on a plane
├── NoBlur
└── GaussianBlur                        ← VGTK Core

AbstractResponse                        collected light → digital value
└── NoResponse                          the identity: the linear flux is the observation

AbstractLight                           the scene's illumination
└── EnvironmentLight (over a SphericalHarmonicMap)   ← VGTK Core

AbstractMaterial                        a surface's reflectance
└── Material (Cook–Torrance / GGX)      ← RC

RadiometricCameraModel{G, F<:AbstractFocus, A<:AbstractAperture, V<:AbstractVignetting, R<:AbstractResponse}
    geometric::G     any VGTK Core camera, unchanged
    focus::F         = NoFocus()
    aperture::A      = NoAperture()
    vignetting::V    = NoVignetting()
    response::R      = NoResponse()
```

Notes on what the tree changes relative to today's code:

- **`NoVignetting` replaces RC's flat default.** RC builds a 4×4
  tensor-product field with `V ≡ 1` when no vignetting is given, and a held
  vignetting keeps its block in the variable vector, masked. With
  `NoVignetting` the block is not there: its parameter vector is empty.
  `NoVignetting` exists today (it subtypes VGTK Core's `AbstractVignetting`
  and answers its parameter protocol); its supertype becomes VRTK Core's own
  `AbstractVignetting` when the abstract type moves.
- **The aperture becomes a type.** Today it is a scalar radius and the flux
  divides by its area, so a pinhole cannot be written. `NoAperture` is the
  pinhole; `DiscAperture` carries today's behaviour unchanged.
- **The focus variant becomes a type.** `Focus.kind` is a run-time branch
  inside the kernel that exists for RC's experiment variants. In VRTK Core the
  kernel dispatches on the focus type; a variant is another subtype, defined
  where it is used.
- **The response is new design, not a move.** RC compares the linear flux
  with linearised observations and lets the light's coefficients carry the
  overall scale. `AbstractResponse` gives that layer (gain, exposure, levels,
  a response curve) a place; only `NoResponse` is needed to move RC, and the
  concrete responses are designed when a consumer needs one. The sensor
  *noise* model is not a response and stays in VGTK Core.
- **Lights and materials get abstract types** so that a kernel is written
  against the part and not against the one concrete model.
- **Zero columns by type, not by mask.** RC's Jacobian layouts take a fixed
  number of blocks (7 per view, 10 per tile) and switch columns by variable
  flags; the dual-number slot offsets are unconditional. For an absent part to
  contribute no variable, the layout is derived from the parts' parameter
  vectors. That is VRTK Estimation's first design task and is why Estimation
  follows Core and does not move with it.
- **The protocol moves with the types.** VGTK Core's quality gate lets another
  package add methods only to its contract generics; the parameter protocol
  (`parameter_vector`, `parameter_names`, `parameter_bounds`,
  `with_parameters`) is one, `coefficient_jacobian`, `control_points`,
  `n_control_points`, `with_control_points` are not. Those four become VRTK
  Core's functions (and its contract generics) when the fields move.
- **Internal helpers.** The moving files call nine underscore-named helpers of
  VGTK Core (sections 2.1 to 2.3). The stack forbids reaching another
  package's private names, so each gets a public spelling in VGTK Core or is
  rewritten on public API, before or with the move.

## 6. The migration sequence

**Zero duplication.** Code is moved, never copied. A type, a function, a file
kind, a test or a fixture has one owner at every commit of every repository:
the change that adds it to its new owner is paired with the change that
removes it from its old owner, and the old owner depends on nothing it gave
away. The root `DUPLICATION.toml` of this repository stays empty: it holds no
exception for moved code, and the stack's duplication gate (which compares the
stack's repositories with each other) is what proves the move was a move. The
same holds for tooling: where the Visual Geometry Toolkit's gates, checks and
conventions can be called, they are called and not restated (the packages'
quality suites do so today).

Where the old and the new owner release at different times, the order of the
releases makes this possible: the new owner's release comes first, the old
owner's retiring release follows in the same cascade, and no release of
either holds the code while the other also does as an owner in use.

| step | where | what | release |
|---|---|---|---|
| 1 | VRTK Core | the vignetting family (the abstract type, the three fields, `BinnedRadialProfile`, the charts, the tags, the protocol) and the lights (`SphericalHarmonicMap`, `EnvironmentLight`, the spherical-harmonic basis), with their tests, docs and precompile workload; `NoVignetting` takes VRTK Core's `AbstractVignetting` | VRTK Core 0.1.0 |
| 2 | VRTK Core | from RC: `RadiometricCameraModel` (field `geometric`), `Focus` / `FocusSpline`, `SensorQuadrature` / `ApertureQuadrature`, `Material` and the Cook–Torrance / GGX kernels, as the part hierarchy of section 5 | same release, or 0.2.0 |
| 3 | VRTK IO | the vignetting, environment-light and radial-profile kinds, same names and bytes, with their version steps, fixtures and schema tests | VRTK IO 0.1.0 |
| 4 | VGTK Core, VGTK IO | retire by name, each with its replacement: the names of step 1 and their kinds are removed, and a use of a removed name is an error that names the VRTK package to load. VGTK IO opens its kind registration to other packages. Breaking: VGTK Core 0.12, VGTK IO 0.11 | VGTK releases |
| 5 | PanoramaStitching | `fit_vignetting` and its precompile, test and example take the vignetting types from VRTK Core; the panorama record becomes PanoramaStitching's own, a thin record over VRTK IO and VGTK IO | PanoramaStitching minor |
| 6 | RC | depends on VRTK Core and VRTK IO; what step 2 moved is deleted from it in the same cascade; `_flat_vignetting` gives way to `NoVignetting` | RC next minor |
| 7 | BlobBoards | no code change (section 7); its suite is re-run on the new VGTK versions | BlobBoards patch, if its compat needs it |
| 8 | VRTK Core, VGTK Core | `GaussianBlur` and `AbstractBlur` move, once the framed-covariance helpers they use are public in VGTK Core; `vgio/blur` follows to VRTK IO | later minors |
| 9 | VRTK Estimation | the new package: RC's calibration (section 4.2) on parts-derived layouts | later |

### Registries

The stack's rule is one registry per package. VisualRadiometryToolkitCore and
VisualRadiometryToolkitIO are registered first in
[CauRegistry](https://github.com/prittjam/CauRegistry.jl) (from this
repository's subdirectories), where RC already is; RC depends on them from
there in its next minor release. General follows later, in dependency order:
VRTK Core, VRTK IO, then RC. A package leaves CauRegistry when its first
General version merges. `RELEASING.md` states the steps.

The order within a cascade is always: the new owner's release, then the old
owner's retiring release, then the dependants. Because VGTK's packages are in
General and VRTK's are first in CauRegistry, a user of a retired name needs
CauRegistry until VRTK reaches General; the retiring VGTK release says so in
its error and changelog. If that is not acceptable for General users of
PanoramaStitching, step 4 waits for VRTK's General registration (section 8).

## 7. Dependants

| dependant | what it uses | change |
|---|---|---|
| **VisualGeometryToolkitIO** | every vignetting, light and blur name, in the files of section 3 | step 3 and 4 |
| **VisualGeometryToolkitFeatures, Estimation, Eval, PoseLib** | no vignetting, light or blur name. Features uses RAW, the noise model and capture settings, which stay | none |
| **PanoramaStitching** 0.5.1 | 6 files: `src/vignetting.jl` (`fit_vignetting`; `LogVignetting`, `RadialVignetting`, `TensorProductVignetting`, `active_coefficients`, `log_spline`, `control_points`, `with_control_points`, `n_control_points`, `pole_regular_basis`), `src/precompile.jl`, `src/panorama.jl` (`AbstractVignetting`), `test/vignetting_tests.jl`, `examples/panorama_vignetting/run.jl` and its config (`VIGNETTING_TAGS`). Its sampling and seam code take a vignetting as a callable `(u, f)` and name no type | step 5: new dependency on VRTK Core (and VRTK IO for the record); imports change, code does not |
| **BlobBoards** | no radiometric type or function. One test (`test/suites/identity_pins.jl`) pins an envelope that contains the token `"radiance": "relative"` | none: the token is the envelope's and stays in VGTK IO. Re-run the pin |
| **RadiometricCamera** 0.1.0 | everything: 23 source files and 36 test files name a VGTK Core radiometric name (`EnvironmentLight`, `SphericalHarmonicMap`, `AbstractVignetting`, `RadialVignetting`, `TensorProductVignetting`, the control-point protocol, `GaussianBlur`, the tags and charts), and it defines what section 4 lists | step 6 |
| CaliBlobs, LightRigCalibration, LocalOptimizationDoneRight, RANSACScoringDoneRight | none | none |

The allow-list (`VisualGeometryToolkitCore/configs/stack_dependencies.toml` in
VGTK, with this repository's rows in
`VisualRadiometryToolkitCore/configs/stack_dependencies.toml`) gains the VRTK
packages as stack packages, and PanoramaStitching's and RC's rows gain them.

## 8. Open decisions

1. **The printed target** (`PrintedTarget`, `BoardSurface`, `Scene`, the
   warping field): into VRTK Core with the kernels, or a surface contract in
   VRTK Core with the printed target staying in RC.
2. **`BinnedRadialProfile`'s supertype.** It is a measured profile, not a
   vignetting model (no control points). Proposed: it stays outside
   `AbstractVignetting`.
3. **General users during the CauRegistry period** (section 6): retire in
   VGTK at once, or keep the VGTK names until VRTK is in General.
4. **Steps 1 and 2 in one release or two.**
5. **`AbstractResponse`**: introduced with `NoResponse` only (proposed), or
   left out until a concrete response is designed.
6. **The symbols of RC's notation** (`𝔣`, `t̂`, `π̂⁻¹`, `𝐩`, `𝐚`): kept as the
   public names in VRTK Core, or given ASCII names under the stack's naming
   convention with the symbols as aliases.

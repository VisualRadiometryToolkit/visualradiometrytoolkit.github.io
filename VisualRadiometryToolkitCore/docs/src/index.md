# VisualRadiometryToolkitCore.jl

The core of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the types of a radiometric camera. A radiometric camera is a camera of the
[Visual Geometry Toolkit](https://visualgeometrytoolkit.github.io) together
with the parts that decide how much light a pixel collects: its vignetting,
its aperture, its focus.

Radiometry lifts geometry. This package depends on
[VisualGeometryToolkitCore](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/)
and follows its conventions (naming, signatures, frames, units, Jacobians),
which are stated once, [there](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/dev/guide/conventions/);
no package of the Visual Geometry Toolkit depends on this one.

The camera model is that of the paper
[Real Cameras are Radiometric](https://arxiv.org/abs/2611.25265).

## What it provides

- the radiometric camera, [`RadiometricCameraModel`](@ref), and its
  back-projection from the aperture disc;
- the focus surface ([`VisualRadiometryToolkitCore.Focus`](@ref)), a thin plate
  spline over the sensor;
- the vignetting fields ([`TensorProductVignetting`](@ref),
  [`RadialVignetting`](@ref), [`LogVignetting`](@ref)), the absent vignetting
  [`NoVignetting`](@ref) and a measured radial profile
  ([`VisualRadiometryToolkitCore.BinnedRadialProfile`](@ref));
- the quadrature rules on a pixel and on the aperture
  ([`VisualRadiometryToolkitCore.SensorQuadrature`](@ref),
  [`VisualRadiometryToolkitCore.ApertureQuadrature`](@ref));
- the scene: an [`EnvironmentLight`](@ref) of a [`SphericalHarmonicMap`](@ref),
  a Cook–Torrance [`VisualRadiometryToolkitCore.Material`](@ref) and a
  [`TexturedTarget`](@ref) with its printed-edge model and its state.

The public names are descriptive: each function is named for what it computes,
and the paper's symbols stay in the paper.

## Installation

```julia-repl
pkg> add VisualGeometryToolkitCore VisualRadiometryToolkitCore StaticArrays
```

Julia 1.13 or later. Every dependency is in the General registry. The
package's own registration in General is pending; until it is merged, `add`
takes the repository's URL and the package's directory,
`https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io:VisualRadiometryToolkitCore`.
VisualGeometryToolkitCore defines the geometric camera that a radiometric
camera holds.

## Example

The example builds a radiometric camera from a pinhole camera, and
back-projects a sensor position from a point of the aperture: the ray goes
through the focus point of that sensor position.

```julia
using VisualGeometryToolkitCore, VisualRadiometryToolkitCore
using StaticArrays: SMatrix, SVector
using LinearAlgebra: norm

# A geometric camera on a 1200 × 800 image: focal length 900 pixels, a pinhole lens.
K = CameraCalibrationMat(SMatrix{3, 3}(900.0, 0, 0, 0, 900.0, 0, 600.0, 400.0, 1))
geometric = BoundedCamera(CameraModel(LogicalIntrinsics(K), Lens(Perspective())), Size2(1200, 800))

# The radiometric camera: focused at 1.5 m, with an aperture of radius 4 mm.
camera = RadiometricCameraModel(geometric; focus = 1.5m, aperture_radius = 4mm)
camera.vignetting === NoVignetting()                   # true

𝐩 = SVector(700.0, 300.0)                              # a sensor position (pixels)
𝐚 = SVector(0.002, 0.0, 0.0)                           # a point of the aperture disc (camera frame, metres)
𝐟 = VisualRadiometryToolkitCore.focus_point(camera, 𝐩) # where the rays of 𝐩 meet (camera frame, metres)
norm(𝐟) ≈ 1.5                                          # true
d = backproject(camera, 𝐩, 𝐚)                          # the unit direction of the ray from 𝐚 through 𝐟
d ≈ (𝐟 - 𝐚) / norm(𝐟 - 𝐚)                              # true
```

A camera that is given no vignetting attenuates nothing, and the absent
vignetting costs nothing: it has no parameters, and its value is `true`, the
identity of the product it enters.

```jldoctest
julia> using VisualGeometryToolkitCore, VisualRadiometryToolkitCore

julia> using StaticArrays: SVector

julia> v = NoVignetting();

julia> v isa AbstractVignetting
true

julia> v(SVector(1200.0, 800.0)) * 0.25
0.25

julia> parameter_names(v)
()
```

## Documentation

- **Explanation**: [Design](@ref), how a radiometric camera is composed and
  the rules its parts follow.
- **Reference**: the [API Reference](@ref) (the camera, its focus surface, the
  sensor and the vignetting fields) and the
  [API Reference: the scene](@ref) (lights, materials, textured targets).

[VisualRadiometryToolkitIO](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/)
saves and loads the vignetting fields, environment lights and radial profiles
of this package.

## Citing

If you use the toolkit, please cite the paper whose camera model it carries:

```bibtex
@article{harder2026radiometric,
  author        = {Harder, Ties and Seegr{\"a}ber, Felix and Nakath, David and
                   Sauer, Hendrik and K{\"o}ser, Kevin and Pritts, James},
  title         = {Real Cameras are Radiometric},
  journal       = {arXiv preprint arXiv:2611.25265},
  year          = {2026},
  eprint        = {2611.25265},
  archivePrefix = {arXiv},
  primaryClass  = {cs.CV},
}
```

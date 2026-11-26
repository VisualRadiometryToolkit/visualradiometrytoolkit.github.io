# VisualRadiometryToolkitCore.jl

[![CI](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/)
[![Coverage](https://codecov.io/gh/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/branch/main/graph/badge.svg?flag=VisualRadiometryToolkitCore)](https://app.codecov.io/gh/VisualRadiometryToolkit/visualradiometrytoolkit.github.io?flags%5B0%5D=VisualRadiometryToolkitCore)

VisualRadiometryToolkitCore holds the types of a radiometric camera: a camera
of [VisualGeometryToolkitCore](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/)
together with what decides how much light a pixel collects (its focus surface,
its aperture radius and its vignetting), and the scene such a camera sees (an
environment light, a Cook–Torrance material and a textured planar target). It
is the core of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io)
and carries the camera model of the paper
[Real Cameras are Radiometric](https://arxiv.org/abs/2611.25265).

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
geometric = BoundedCamera(CameraModel(LogicalIntrinsics(K), Pinhole()), Size2(1200, 800))

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

## Documentation

- [Design](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/guide/design/):
  how a radiometric camera is composed from a geometric camera, and the rules
  its parts follow.
- [API Reference](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/api/):
  the camera, its focus surface, the sensor's quadrature rules and the
  vignetting fields.
- [API Reference: the scene](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/dev/api_scene/):
  lights, materials and textured targets.

[VisualRadiometryToolkitIO](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/dev/)
saves and loads the vignetting fields, environment lights and radial profiles
of this package. The conventions (naming, frames, units) are those of
VisualGeometryToolkitCore, stated on its
[Conventions](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/stable/guide/conventions/)
page.

## Citing

If you use the package, please cite the paper whose camera model it carries:

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

## License

MIT. See [LICENSE](LICENSE).

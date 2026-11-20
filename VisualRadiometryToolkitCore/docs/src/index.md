# VisualRadiometryToolkitCore.jl

The core of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the types of a radiometric camera. A radiometric camera is a camera of the
[Visual Geometry Toolkit](https://visualgeometrytoolkit.github.io) together
with the parts that decide how much light a pixel collects: its vignetting,
its aperture, its focus, its sensor's response.

Radiometry lifts geometry. This package depends on
[VisualGeometryToolkitCore](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/)
and follows its conventions (naming, signatures, frames, units, Jacobians),
which are stated once, [there](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitCore/dev/guide/conventions/);
no package of the Visual Geometry Toolkit depends on this one.

The package holds the radiometric camera as one object,
[`RadiometricCameraModel`](@ref): any geometric camera with its focus surface
([`VisualRadiometryToolkitCore.Focus`](@ref)), its aperture radius and its
vignetting ([`NoVignetting`](@ref) unless one is stated); the camera's
back-projection from the aperture disc; the sensor's pixels and the quadrature
rules of the image-formation integrals; the scene's light
([`EnvironmentLight`](@ref)) and a surface's reflectance
([`VisualRadiometryToolkitCore.Material`](@ref)). The [Design](@ref) page states
the rules its parts follow.

!!! warning "Not registered yet"
    The package is at the placeholder version 0.0.1 and is not in a registry.

## Installation

```julia-repl
pkg> add https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io:VisualRadiometryToolkitCore
```

Julia 1.13 or later. Every dependency is in the General registry.

## Example

A camera that is given no vignetting attenuates nothing, and the absent
vignetting costs nothing: it has no parameters, and a kernel that multiplies by
its value is compiled to one that does not multiply.

```julia
using VisualGeometryToolkitCore, VisualRadiometryToolkitCore
using StaticArrays: SMatrix, SVector

K = CameraCalibrationMat(SMatrix{3, 3}(900.0, 0, 0, 0, 900.0, 0, 600.0, 400.0, 1))
geometric = BoundedCamera(CameraModel(LogicalIntrinsics(K), Pinhole()), Size2(1200, 800))   # any geometric camera, on its pixels
camera = RadiometricCameraModel(geometric; focus = 1.5, aperture_radius = 0.004)             # focused at 1.5 m, a 4 mm aperture radius
camera.vignetting                                                                            # NoVignetting(): none was stated
𝐩 = SVector(700.0, 300.0)                                                                    # a sensor position (COLMAP pixels)
𝐚 = SVector(0.002, 0.0, 0.0)                                                                 # a point of the aperture disc (camera frame, m)
VisualRadiometryToolkitCore.π̂⁻¹(camera, 𝐩, 𝐚)                                                # the ray's unit direction from 𝐚 to the focus point of 𝐩
```

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

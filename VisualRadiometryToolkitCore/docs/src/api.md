# API Reference

```@docs
VisualRadiometryToolkitCore
```

## The radiometric camera

A [`RadiometricCameraModel`](@ref) is one object: a geometric camera of
VisualGeometryToolkitCore (`geometric`), a focus surface, an aperture radius
and a vignetting. Composed from a geometric camera it has
[`NoVignetting`](@ref) unless one is stated. Its camera-frame maps are the
unit chief direction (`chief_direction`), the focus point `focus_point` on
the Petzval surface (the paper's `𝔣(𝐩)`) and the radiometric back-projection
(the paper's `π̂⁻¹(𝐩, 𝐚)`), the direction of the ray from the aperture point `𝐚`
to the focus point; `world_ray` is that ray at a pose. Each has one
implementation, on the parts it reads, so a record that holds the same parts
forwards to it.

The radiometric back-projection of a camera is a method of
VisualGeometryToolkitCore's `backproject`, with the aperture point as a third
argument: `backproject(camera, 𝐩)` is the geometric camera's chief ray,
`backproject(camera, 𝐩, 𝐚)` the ray from the aperture point `𝐚`. On a camera's
parts it is `aperture_direction`.

```@docs
VisualRadiometryToolkitCore.backproject(::RadiometricCameraModel, ::VisualRadiometryToolkitCore.StaticVector{2}, ::VisualRadiometryToolkitCore.StaticVector{3})
```

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/radiometric_camera.jl", "VisualRadiometryToolkitCore.jl"]
Filter = t -> t !== VisualRadiometryToolkitCore && t !== VisualRadiometryToolkitCore.backproject
```

## Focus

The focus surface: the inverse focus distance (`inverse_focus_distance`, the
paper's `t̂ = 1/𝔱`) along each chief ray,
a thin plate spline of VisualGeometryToolkitCore over nodes on the sensor. A `Focus`
is isbits, for a kernel; its solver, a `FocusSpline`, stays on the host.

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/focus.jl"]
```

## Sensor and quadrature

Sensor positions are COLMAP pixels of the image, `𝐩 ∈ [0, W] × [0, H]`; Julia's
1-based pixel `(u, v)` has its centre at `sensor_position(u, v)`. The integrals of
the image formation are evaluated by fixed rules: a tensor Gauss–Legendre rule
on a pixel's footprint and a polar rule on the aperture disc, in statically
sized containers a kernel takes unchanged.

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["sensor/notation.jl", "sensor/quadrature.jl"]
```

## Vignetting

A camera's relative illumination V on the sensor. [`NoVignetting`](@ref) is the
absent one, `V ≡ 1`. The fields are B-splines on clamped knots, linear in their
control points: a tensor-product surface over a sensor box
([`TensorProductVignetting`](@ref)) or a profile in the radius about a centre
([`RadialVignetting`](@ref)); [`LogVignetting`](@ref) reads either as the spline
of log V. A field is callable, `v(u)`, and isbits, so a batch of sensor points
goes through VisualGeometryToolkitCore's `pointwise!` on a device;
[`VisualRadiometryToolkitCore.coefficient_jacobian`](@ref) is its row of a least
squares in the control points,
[`VisualRadiometryToolkitCore.active_coefficients`](@ref) that row's nonzeros,
and [`VisualRadiometryToolkitCore.pole_regular_basis`](@ref) the radial profiles
smooth at their centre. The estimators that fit them are their owners': a
radiometric calibration's, a panorama's self-calibration.

A radial profile reads its normalized radius on a chart of the distance from
its centre ([`VisualRadiometryToolkitCore.AbstractRadialChart`](@ref)): `LinearChart()`,
`ρ = d / radius`, constant beyond the radius; or `ProjectiveChart()`, `ρ = d / (radius + d)`,
½ at the radius and never beyond the knots. A stored chart is its tag
([`VisualRadiometryToolkitCore.RADIAL_CHART_TAGS`](@ref)).

```julia
v = RadialVignetting(12, SVector(2128.0, 1424.0), 1700.0)   # control points, centre and radius (camera pixels); V ≡ 1
w = RadialVignetting(15, SVector(2128.0, 1424.0), 2560.0; chart = ProjectiveChart())   # ρ = ½ at the farthest corner
v(SVector(2500.0, 1300.0))                                   # V at a sensor point
```

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/vignetting.jl"]
```

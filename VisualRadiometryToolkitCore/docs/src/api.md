# API Reference

```@docs
VisualRadiometryToolkitCore
```

## The radiometric camera

A [`RadiometricCameraModel`](@ref) is one object: a geometric camera of
VisualGeometryToolkitCore (`geometric`), a focus surface, an aperture radius
and a vignetting. Composed from a geometric camera it has
[`NoVignetting`](@ref) unless one is stated. Its camera-frame maps are the
unit chief direction, the focus point `𝔣(𝐩)` on the Petzval surface and the
radiometric back-projection `π̂⁻¹(𝐩, 𝐚)`, the direction of the ray from the
aperture point `𝐚` to the focus point; `world_ray` is that ray at a pose. Each
has one implementation, on the parts it reads, so a record that holds the same
parts forwards to it.

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/radiometric_camera.jl", "VisualRadiometryToolkitCore.jl"]
Filter = t -> t !== VisualRadiometryToolkitCore
```

## Focus

The focus surface: the inverse focus distance `t̂ = 1/𝔱` along each chief ray,
a thin plate spline of VisualGeometryToolkitCore over nodes on the sensor (or,
as an experiment, over the chief directions: a chart or the sphere). A `Focus`
is isbits, for a kernel; its solver, a `FocusSpline`, stays on the host.

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/focus.jl", "camera/focus_charts.jl"]
```

## Sensor and quadrature

Sensor positions are COLMAP pixels of the image, `𝐩 ∈ [0, W] × [0, H]`; Julia's
1-based pixel `(u, v)` has its centre at `𝐩_of_pixel(u, v)`. The integrals of
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
its centre ([`VisualRadiometryToolkitCore.RADIAL_CHARTS`](@ref)): linear,
`ρ = d / radius`, constant beyond the radius; or projective, `ρ = d / (radius + d)`,
½ at the radius and never beyond the knots.

```julia
v = RadialVignetting(12, SVector(2128.0, 1424.0), 1700.0)   # control points, centre and radius (camera pixels); V ≡ 1
w = RadialVignetting(15, SVector(2128.0, 1424.0), 2560.0; chart = :projective)   # ρ = ½ at the farthest corner
v(SVector(2500.0, 1300.0))                                   # V at a sensor point
```

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["camera/vignetting.jl"]
```

## Lights

The scene's light as a radiometric camera sees it: an [`EnvironmentLight`](@ref),
radiance from every direction given by a directional map on a sphere of finite
radius about a centre, looked up where a ray from the shaded point leaves the
sphere (the distant light is its limit as the radius grows). The map is a
[`SphericalHarmonicMap`](@ref): real spherical harmonics per channel
(orthonormal, no Condon–Shortley phase), so the radiance is linear in the
coefficients. Everything is isbits and allocation-free, for a kernel; the
centre and radius are lengths (`ustrip(m, light)` for the kernel's plain form).

```julia
light = EnvironmentLight(SphericalHarmonicMap(a, 2), SVector(0.0, 0.0, 0.0), 1.5)   # 3 × 9 coefficients, centre, radius
VisualRadiometryToolkitCore.radiance(light, x, ω)            # per channel, arriving at x from direction ω
```

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["scene/lights.jl"]
```

## Materials

A surface's reflectance: a spatially varying Cook–Torrance BSDF, a diffuse
term and a GGX microfacet specular term with a dielectric Fresnel factor, whose
roughness and index of refraction blend between two endpoints by a texture
value. The pieces are scalar functions, generic in the number type (dual
numbers, `Float32` in a kernel).

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["scene/materials.jl"]
```

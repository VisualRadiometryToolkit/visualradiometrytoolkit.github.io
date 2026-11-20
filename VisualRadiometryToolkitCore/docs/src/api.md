# API Reference

```@docs
VisualRadiometryToolkitCore
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

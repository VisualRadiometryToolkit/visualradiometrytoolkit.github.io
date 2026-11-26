# API Reference: the scene

The scene's light, a surface's reflectance and a printed planar target. The camera, its parts and the sensor are on the
[API Reference](@ref) page.

## Lights

The scene's light as a radiometric camera sees it: an [`EnvironmentLight`](@ref),
radiance from every direction given by a directional map on a sphere of finite
radius about a centre, looked up where a ray from the shaded point leaves the
sphere (the distant light is its limit as the radius grows). The map is a
[`SphericalHarmonicMap`](@ref): real spherical harmonics per channel
(orthonormal, no Condon–Shortley phase), so the radiance is linear in the
coefficients. Everything is isbits and allocation-free, for a kernel; the
centre and radius are lengths (`ustrip(m, light)` for the kernel's plain form).

A map's terms are named by their degree and order `(l, m)`; a light about a board takes the sphere that holds the board's
cameras and its whole page:

```julia
sky = SphericalHarmonicMap(2, (0, 0) => (2.0, 1.9, 1.8), (1, 0) => (0.4, 0.3, 0.2))   # a coloured light, brighter towards +z
coefficients(sky, 1, 0)                                       # (0.4, 0.3, 0.2)
light = EnvironmentLight(sky, board, poses)                   # about the board's centre, holding every camera and corner
light = EnvironmentLight(sky, SVector(0.0, 0.0, 0.0), 1.5)    # or a centre and a radius
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

## Textured targets

A [`TexturedTarget`](@ref) is a printed planar target as the radiometry sees
it: VisualGeometryToolkitCore's posed planar target (the geometry and the
design stay there: `PosedTarget`, `PlanarTarget`, `Canvas`, `CanvasTexture`,
`Quad`, `MappedSurface`) with its appearance attached — the texture (`albedo`,
the paper's `ρ_c`), and for a design given as a distance map the printed-edge
model (`edge_albedo`: the ink spread and the print's blur). What a renderer
reads at a ray's hit is `physical_albedo`, the albedo at the design point the
physical page point shows under the in-plane print error; `anchored_albedo` is
the same at a point given as a Float64 anchor and a kernel's Float32 offset,
read in the anchor's precision. The target holds
its own state, a `TargetState`: the nodal heights of its warping, the printed
edge and the in-plane print error, isbits and replaced by value
(`with_state`, `with_h`, `with_edge`, `with_inplane`), so a kernel keeps the
target's arrays on a device and differentiates the state. Its centre is
VisualGeometryToolkitCore's `centroid`, the paper's `𝔟`.

A bare board posed in the world is a target: `TexturedTarget(PosedTarget(Board(Size2(width = 2m, height = 2m), [-1m, -1m]),
pose), texture)` lays the texture over the board when the target has no canvas. The board faces the side its cameras are on:
a camera's calibration state or render orients it by the camera's pose, `with_facing(board, viewpoint)`; until then it faces
the design's +z, the printed side of the design chart.

```@autodocs
Modules = [VisualRadiometryToolkitCore]
Private = false
Pages = ["scene/target_state.jl", "scene/textured_target.jl", "scene/target_warping.jl", "scene/printed_edge.jl"]
```

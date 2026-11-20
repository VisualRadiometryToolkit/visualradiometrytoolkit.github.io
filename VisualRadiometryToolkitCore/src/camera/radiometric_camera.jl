# ---------------------------------------------------------------------------
# The radiometric camera and its back-projection.
#
#   π⁻¹(𝐩)          central (chief-ray) back-projection of the geometric camera
#   d̂(𝐩)            = π⁻¹(𝐩)/‖π⁻¹(𝐩)‖   UNIT chief direction (`chief_dir`): a spline camera's bicubic blend of unit node directions is
#                                        not unit (≤ 2e-4 off inside the image circle), the parametric models are. The focus point
#                                        uses the unit direction, so 1/t̂(𝐩) IS the distance from 𝔭 to 𝔣(𝐩).
#   𝔣(𝐩)            = 𝔭 + 𝔱(𝐩) d̂(𝐩)    focus point on the Petzval surface 𝔉
#   π̂⁻¹(𝐩, 𝐚)      = (𝔣(𝐩) − 𝐚)/‖𝔣(𝐩) − 𝐚‖   direction of the ray from aperture point 𝐚
#                    = (d̂(𝐩) − t̂(𝐩) 𝐚)/‖…‖   (same direction, regular at t̂ = 0)
#
# Camera frame: CV convention (+x right, +y down, +z forward); the aperture 𝒜 is
# the disc of radius r in the plane z = 0 centred at 𝔭 = 0.
#
# ONE implementation of each map, on the parts it reads — the geometric camera and the focus surface (`𝔣(geometric, focus, 𝐩)`,
# `t̂(geometric, focus, 𝐩)`, `π̂⁻¹(geometric, focus, 𝐩, 𝐚)`), the unit chief direction (`π̂⁻¹(d̂, 𝐚, t̂)`), a pose and a camera-frame
# ray (`world_ray(pose, 𝐚, d)`). A `RadiometricCameraModel` forwards to them, and so does any other record that holds the same
# parts (a renderer's flattened per-photograph record): a one-line method, never a second body.
# ---------------------------------------------------------------------------

"""
    RadiometricCameraModel(geometric, focus, aperture_radius, vignetting)

The radiometric camera as ONE object: the geometric camera π⁻¹ (`geometric`: any VisualGeometryToolkitCore camera on the sensor's
pixels; Θ_d), the focus surface (`focus`, a [`Focus`](@ref), Θ_f), the aperture radius r (`aperture_radius`, metres) and the
vignetting V (`vignetting`, an [`AbstractVignetting`](@ref), Θ_v; [`NoVignetting`](@ref) when the camera has none). Every function
of the camera takes it whole: a photograph is the camera at a pose (camera → world, VisualGeometryToolkitCore's `EuclideanMap`),
[`world_ray`](@ref)`(camera, pose, 𝐩, 𝐚)`.

The image distance is not a parameter: the defocus is the focus surface t̂(𝐩) along each chief ray, and the cos⁴/s′² obliquity is in V.
"""
struct RadiometricCameraModel{L, F <: Focus, T <: Real, V <: AbstractVignetting}
    geometric::L
    focus::F
    aperture_radius::T
    vignetting::V
end
"""
    RadiometricCameraModel(geometric; focus, aperture_radius, vignetting = NoVignetting())

The radiometric camera composed from its geometric camera `geometric` (a VisualGeometryToolkitCore camera bounded by its image: a
`BoundedCamera` of a `CameraModel` over any lens, a spline camera included; the camera's field `geometric`) by adding the three
parts a geometric camera lacks:

- `focus`: the focus surface, a [`Focus`](@ref), or a distance in metres — the surface focused at that distance everywhere
  (`Focus(geometric, distance)`, a 3 × 3 thin plate spline on the camera's image);
- `aperture_radius`: the radius r of the aperture disc, metres;
- `vignetting`: an [`AbstractVignetting`](@ref) on the camera's image; by default the absent one, [`NoVignetting`](@ref): V ≡ 1 with
  no parameters, which a kernel does not multiply by. A field to estimate is stated: a [`TensorProductVignetting`](@ref) or a
  [`RadialVignetting`](@ref).

The image size is the geometric camera's (`extent`): it is stated once. The camera's parts are replaced one at a time by
[`with_geometric`](@ref), [`with_focus`](@ref), [`with_aperture_radius`](@ref) and [`with_vignetting`](@ref).
"""
function RadiometricCameraModel(geometric::BoundedCamera; focus, aperture_radius::Real,
                                vignetting::AbstractVignetting = NoVignetting())
    return RadiometricCameraModel(geometric, _focus_surface(geometric, focus), aperture_radius, vignetting)
end
_focus_surface(geometric, focus::Focus) = focus
_focus_surface(geometric, distance::Real) = Focus(geometric, distance)

"""
    Focus(geometric, focus_distance; n = 3, T = Float64)

The constant focus surface `𝔱 ≡ focus_distance` (metres) on the `n × n` grid of the image of the geometric camera `geometric` (its
`extent`): `Focus(n, focus_distance, W, H)`.
"""
function Focus(geometric::BoundedCamera, focus_distance::Real; n::Integer = 3, T = Float64)
    W, H = extent(geometric)
    return Focus(n, focus_distance, W, H; T)
end

"""
    with_geometric(camera::RadiometricCameraModel, geometric) -> RadiometricCameraModel

The camera with its geometric camera (the field `geometric`, Θ_d) replaced.
"""
with_geometric(c::RadiometricCameraModel, geometric) = RadiometricCameraModel(geometric, c.focus, c.aperture_radius, c.vignetting)
"""
    with_focus(camera::RadiometricCameraModel, focus::Focus) -> RadiometricCameraModel

The camera with its focus surface (Θ_f) replaced.
"""
with_focus(c::RadiometricCameraModel, f::Focus) = RadiometricCameraModel(c.geometric, f, c.aperture_radius, c.vignetting)
"""
    with_aperture_radius(camera::RadiometricCameraModel, r) -> RadiometricCameraModel

The camera with its aperture radius r (metres) replaced.
"""
with_aperture_radius(c::RadiometricCameraModel, r::Real) = RadiometricCameraModel(c.geometric, c.focus, r, c.vignetting)
"""
    with_vignetting(camera::RadiometricCameraModel, vignetting::AbstractVignetting) -> RadiometricCameraModel

The camera with its vignetting replaced.
"""
with_vignetting(c::RadiometricCameraModel, v::AbstractVignetting) = RadiometricCameraModel(c.geometric, c.focus, c.aperture_radius, v)
"""
    focus(camera::RadiometricCameraModel) -> Focus

The camera's focus surface (Θ_f).
"""
focus(c::RadiometricCameraModel) = c.focus
"""
    aperture_radius(camera::RadiometricCameraModel)

The camera's aperture radius r, in metres.
"""
aperture_radius(c::RadiometricCameraModel) = c.aperture_radius
"""
    geometric(camera::RadiometricCameraModel)

The camera's geometric camera π⁻¹ (Θ_d): a VisualGeometryToolkitCore camera. Its lens model is VisualGeometryToolkitCore's
`lens(geometric(camera))`.
"""
geometric(c::RadiometricCameraModel) = c.geometric
# the geometric camera's maps (VisualGeometryToolkitCore's contract generics), forwarded to it
project(c::RadiometricCameraModel, X) = project(c.geometric, X)
backproject(c::RadiometricCameraModel, 𝐩) = backproject(c.geometric, 𝐩)

"""Centre of projection 𝔭 (origin of the camera frame)."""
const 𝔭 = SVector(0.0, 0.0, 0.0)

"""
    chief_ray(geometric, 𝐩) -> SVector{3}

The image formation's chief ray of the sensor position 𝐩 ∈ ℐ = [0, W] × [0, H] (COLMAP pixels) through the geometric camera
`geometric` (camera frame: x right, y down, z forward; not necessarily unit): what a geometric camera answers to carry a
radiometric camera. Generic in the element type (Float32, `ForwardDiff.Dual`) and usable in a device kernel (isbits, no throws).

- Any VisualGeometryToolkitCore camera: its `backproject(geometric, 𝐩)` (a unit ray; NaN where the lens does not image the point).
- A `SplineLens` camera: its backward spline's VALUE at K⁻¹𝐩 (the lattice evaluation, NOT normalized) — linear in the lattice's
  direction nodes, which a calibration's Jacobian fan-out onto them relies on; a node's norm is a weight, not a gauge.

Only the image formation reads it ([`chief_dir`](@ref) normalizes it); every other back-projection is `backproject`. A camera type
of another package answers it with a method (it is one of this package's `CONTRACT_GENERICS`).
"""
@inline chief_ray(geometric, 𝐩::StaticVector{2}) = SVector{3}(backproject(geometric, 𝐩))
@inline chief_ray(g::CameraModel{<:AbstractIntrinsics, <:SplineLens}, 𝐩::StaticVector{2}) =
    SVector{3}(g.lens.backward(normalized_point(g.intrinsics, 𝐩)))   # the lattice evaluation at K⁻¹𝐩 (VisualGeometryToolkitCore's normalized point)
@inline chief_ray(g::BoundedCamera{<:CameraModel{<:AbstractIntrinsics, <:SplineLens}}, 𝐩::StaticVector{2}) = chief_ray(model(g), 𝐩)

"""
    chief_dir(geometric, 𝐩) -> SVector{3}
    chief_dir(camera::RadiometricCameraModel, 𝐩) -> SVector{3}

Unit chief direction d̂(𝐩) = π⁻¹(𝐩)/‖π⁻¹(𝐩)‖ of a sensor position ([`chief_ray`](@ref), normalized): the direction along which the
focus point 𝔣(𝐩) lies at the distance 1/t̂(𝐩) from the centre of projection. `π⁻¹` of a spline camera is a bicubic blend of unit
node directions and is not unit (≤ 2e-4 off inside the image circle on real lattices); the parametric models return unit vectors.
Dual-generic: when `π⁻¹` carries partials the normalisation projects them onto the tangent plane of d̂.
"""
@inline chief_dir(geometric, 𝐩::StaticVector{2}) = normalize(chief_ray(geometric, 𝐩))
@inline chief_dir(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = chief_dir(c.geometric, 𝐩)

"""
    t̂(geometric, focus::Focus, 𝐩)
    t̂(camera::RadiometricCameraModel, 𝐩)

The camera's inverse focus distance at the sensor position 𝐩. EXPERIMENT (focus-ab): the sensor TPS at 𝐩 (kind 0), or a
direction chart's surface at the chief direction of 𝐩 through the geometric camera (kinds 1, 2; focus_charts.jl).
"""
@inline t̂(geometric, f::Focus, 𝐩::StaticVector{2}) = f.kind == 0 ? t̂(f, 𝐩) : t̂_dir(f, chief_dir(geometric, 𝐩))
@inline t̂(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = t̂(c.geometric, c.focus, 𝐩)

"""
    𝔣(geometric, focus::Focus, 𝐩) -> SVector{3}
    𝔣(camera::RadiometricCameraModel, 𝐩) -> SVector{3}

Focus point 𝔣(𝐩) = 𝔱(𝐩) d̂(𝐩) on the Petzval surface, d̂ the UNIT chief direction (camera frame, the centre of projection
𝔭 = 0): ‖𝔣(𝐩)‖ = 𝔱(𝐩) = 1/t̂(𝐩) exactly, for every lens class.
"""
@inline 𝔣(geometric, f::Focus, 𝐩::StaticVector{2}) = inv(t̂(geometric, f, 𝐩)) * chief_dir(geometric, 𝐩)
@inline 𝔣(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = 𝔣(c.geometric, c.focus, 𝐩)

"""
    π̂⁻¹(d̂, 𝐚, t̂) -> SVector{3}
    π̂⁻¹(geometric, focus::Focus, 𝐩, 𝐚) -> SVector{3}
    π̂⁻¹(geometric, 𝐩, 𝐚, t̂) -> SVector{3}
    π̂⁻¹(camera::RadiometricCameraModel, 𝐩, 𝐚[, t̂]) -> SVector{3}

Radiometric extension: unit direction from the aperture point 𝐚 towards 𝔣(𝐩) (camera frame),
computed as `normalize(d̂(𝐩) − t̂(𝐩) 𝐚)` with the unit chief direction d̂ = `chief_dir(𝐩)` (regular for focus at infinity).
`π̂⁻¹(𝐩, 𝔭) = π⁻¹(𝐩)`. The first form is the implementation, on a unit chief direction `d̂` and an inverse focus distance `t̂`
the caller evaluated (once per sensor sample); the forms with a trailing `t̂` take it hoisted the same way.
"""
@inline function π̂⁻¹(d̂::StaticVector{3}, 𝐚::StaticVector{3}, t̂val)
    d = d̂ - t̂val * 𝐚
    return d / sqrt(d[1]^2 + d[2]^2 + d[3]^2)
end
@inline π̂⁻¹(geometric, f::Focus, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}) = π̂⁻¹(chief_dir(geometric, 𝐩), 𝐚, t̂(geometric, f, 𝐩))
@inline π̂⁻¹(geometric, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}, t̂val) = π̂⁻¹(chief_dir(geometric, 𝐩), 𝐚, t̂val)
@inline π̂⁻¹(c::RadiometricCameraModel, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}) = π̂⁻¹(c.geometric, c.focus, 𝐩, 𝐚)
@inline π̂⁻¹(c::RadiometricCameraModel, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}, t̂val) = π̂⁻¹(c.geometric, 𝐩, 𝐚, t̂val)

"""
    world_ray(pose, 𝐚, d) -> (origin, direction)
    world_ray(camera::RadiometricCameraModel, pose, 𝐩, 𝐚) -> (origin, direction)

Ray of the sensor position 𝐩 through the aperture point 𝐚 of `camera` at `pose` (camera → world, VisualGeometryToolkitCore's
`EuclideanMap`), in world coordinates. The first form is the implementation: the ray from the aperture point 𝐚 along the
camera-frame direction `d` (a [`π̂⁻¹`](@ref)), moved by `pose` (a plain, unlabeled map, as a kernel holds it); the camera's form
takes any pose and reads it unlabeled.
"""
@inline world_ray(pose::EuclideanMap, 𝐚::StaticVector{3}, d::StaticVector{3}) = (pose(𝐚), pose.R * d)
@inline function world_ray(c::RadiometricCameraModel, pose::EuclideanMap, 𝐩::StaticVector{2}, 𝐚::StaticVector{3})
    return world_ray(unlabel(pose), 𝐚, π̂⁻¹(c, 𝐩, 𝐚))
end

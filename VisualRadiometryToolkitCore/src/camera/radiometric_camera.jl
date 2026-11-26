# ---------------------------------------------------------------------------
# The radiometric camera and its back-projection.
#
#   π⁻¹(𝐩)          central (chief-ray) back-projection of the geometric camera
#   d̂(𝐩)            = π⁻¹(𝐩)/‖π⁻¹(𝐩)‖   UNIT chief direction (`chief_direction`): a spline camera's bicubic blend of unit node directions is
#                                        not unit (≤ 2e-4 off inside the image circle), the parametric models are. The focus point
#                                        uses the unit direction, so 1/t̂(𝐩) IS the distance from 𝔭 to 𝔣(𝐩).
#   𝔣(𝐩)            = 𝔭 + 𝔱(𝐩) d̂(𝐩)    focus point on the Petzval surface 𝔉
#   π̂⁻¹(𝐩, 𝐚)      = (𝔣(𝐩) − 𝐚)/‖𝔣(𝐩) − 𝐚‖   direction of the ray from aperture point 𝐚
#                    = (d̂(𝐩) − t̂(𝐩) 𝐚)/‖…‖   (same direction, regular at t̂ = 0)
#
# Camera frame: CV convention (+x right, +y down, +z forward); the aperture 𝒜 is
# the disc of radius r in the plane z = 0 centred at 𝔭 = 0.
#
# ONE implementation of each map, on the parts it reads — the geometric camera and the focus surface (`focus_point(geometric, focus, 𝐩)`,
# `inverse_focus_distance(geometric, focus, 𝐩)`, `aperture_direction(geometric, focus, 𝐩, 𝐚)`), the unit chief direction
# (`aperture_direction(d̂, 𝐚, t̂)`), a pose and a camera-frame
# ray (`world_ray(pose, 𝐚, d)`). A `RadiometricCameraModel` forwards to them, and so does any other record that holds the same
# parts (a renderer's flattened per-photograph record): a one-line method, never a second body.
#
# The public names are descriptive; the paper's symbols are public ALIASES of the same functions (`𝔭`, `𝔣`, `t̂`, `𝔱`, and `π̂⁻¹`,
# which is VisualGeometryToolkitCore's `backproject`: the radiometric back-projection is its method with the aperture point as a
# third argument). The part-wise back-projection is `aperture_direction`: a method of `backproject` on a bare direction or on a
# geometric camera of VisualGeometryToolkitCore would be a method on that package's function over its own types.
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

- `focus`: the focus surface, a [`Focus`](@ref), or a distance — a length (`1.5m`) or plain metres — the surface focused at that
  distance everywhere (`Focus(geometric, distance)`, a 3 × 3 thin plate spline on the camera's image);
- `aperture_radius`: the radius r of the aperture disc, a length (`2mm`) or plain metres; or `f_number` N instead: the
  photographer's stop, r = f / 2N with f the camera's focal length as a length (VisualGeometryToolkitCore's
  `metric_focal_length`: a camera bounded by its sensor, `BoundedCamera(8mm, sensor; lens)`);
- `vignetting`: an [`AbstractVignetting`](@ref) on the camera's image; by default the absent one, [`NoVignetting`](@ref): V ≡ 1 with
  no parameters, which a kernel does not multiply by. A field to estimate is stated: a [`TensorProductVignetting`](@ref) or a
  [`RadialVignetting`](@ref).

Lengths are taken in metres at construction (the camera stores plain metres, as its kernels read them). The image size is the
geometric camera's (`extent`): it is stated once. The camera's parts are replaced one at a time by [`with_geometric`](@ref),
[`with_focus`](@ref), [`with_aperture_radius`](@ref) and [`with_vignetting`](@ref).
"""
function RadiometricCameraModel(geometric::BoundedCamera; focus, aperture_radius = nothing, f_number = nothing,
                                vignetting::AbstractVignetting = NoVignetting())
    (aperture_radius === nothing) == (f_number === nothing) &&
        throw(ArgumentError("RadiometricCameraModel: state the aperture once, its `aperture_radius` (a length) or its `f_number`"))
    r = aperture_radius === nothing ? _stop_radius(geometric, f_number) : strip_or_bare(VgtkCore.m, aperture_radius)
    return RadiometricCameraModel(geometric, _focus_surface(geometric, focus), r, vignetting)
end
# the aperture radius of the stop N: f / 2N, f the camera's metric focal length, in metres
function _stop_radius(geometric::BoundedCamera, N::Real)
    isfinite(N) && N > 0 || throw(ArgumentError("RadiometricCameraModel: the f-number is positive and finite, got $N"))
    return FlexUnits.ustrip(VgtkCore.m, VgtkCore.metric_focal_length(geometric)) / (2 * N)
end
_focus_surface(geometric, focus::Focus) = focus
_focus_surface(geometric, distance) = Focus(geometric, distance)

"""
    Focus([T = Float64,] geometric, distance; n = 3)

The constant focus surface `𝔱 ≡ distance` (a length, or plain metres) on the `n × n` grid of the image of the geometric camera
`geometric` (its `extent`): `Focus(T, n, distance, W, H)`.
"""
function Focus(::Type{T}, geometric::BoundedCamera, distance; n::Integer = 3) where {T}
    W, H = extent(geometric)
    return Focus(T, n, strip_or_bare(VgtkCore.m, distance), W, H)
end
Focus(geometric::BoundedCamera, distance; n::Integer = 3) = Focus(Float64, geometric, distance; n)

"""
    with_geometric(camera::RadiometricCameraModel, geometric) -> RadiometricCameraModel

The camera with its geometric camera (the field `geometric`, Θ_d) replaced.
"""
with_geometric(c::RadiometricCameraModel, geometric) = @set c.geometric = geometric
"""
    with_focus(camera::RadiometricCameraModel, focus::Focus) -> RadiometricCameraModel

The camera with its focus surface (Θ_f) replaced.
"""
with_focus(c::RadiometricCameraModel, f::Focus) = @set c.focus = f
"""
    with_aperture_radius(camera::RadiometricCameraModel, r) -> RadiometricCameraModel

The camera with its aperture radius r (metres) replaced.
"""
with_aperture_radius(c::RadiometricCameraModel, r::Real) = @set c.aperture_radius = r
"""
    with_vignetting(camera::RadiometricCameraModel, vignetting::AbstractVignetting) -> RadiometricCameraModel

The camera with its vignetting replaced.
"""
with_vignetting(c::RadiometricCameraModel, v::AbstractVignetting) = @set c.vignetting = v
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

"""
    center_of_projection

The centre of projection, the origin of the camera frame: the paper's `𝔭`.
"""
const center_of_projection = SVector(0.0, 0.0, 0.0)
"""
    chief_ray(geometric, 𝐩) -> SVector{3}

The image formation's chief ray of the sensor position 𝐩 ∈ ℐ = [0, W] × [0, H] (COLMAP pixels) through the geometric camera
`geometric` (camera frame: x right, y down, z forward; not necessarily unit): what a geometric camera answers to carry a
radiometric camera. Generic in the element type (Float32, `ForwardDiff.Dual`) and usable in a device kernel (isbits, no throws).

- Any VisualGeometryToolkitCore camera: its `backproject(geometric, 𝐩)` (a unit ray; NaN where the lens does not image the point).
- A `SplineLens` camera: its backward spline's VALUE at K⁻¹𝐩 (the lattice evaluation, NOT normalized) — linear in the lattice's
  direction nodes, which a calibration's Jacobian fan-out onto them relies on; a node's norm is a weight, not a gauge.

Only the image formation reads it ([`chief_direction`](@ref) normalizes it); every other back-projection is `backproject`. A camera type
of another package answers it with a method (it is one of this package's `CONTRACT_GENERICS`).
"""
@inline chief_ray(geometric, 𝐩::StaticVector{2}) = SVector{3}(backproject(geometric, 𝐩))
@inline chief_ray(g::CameraModel{<:AbstractIntrinsics, <:SplineLens}, 𝐩::StaticVector{2}) =
    SVector{3}(g.lens.backward(normalized_point(g.intrinsics, 𝐩)))   # the lattice evaluation at K⁻¹𝐩 (VisualGeometryToolkitCore's normalized point)
@inline chief_ray(g::BoundedCamera{<:CameraModel{<:AbstractIntrinsics, <:SplineLens}}, 𝐩::StaticVector{2}) = chief_ray(model(g), 𝐩)

"""
    chief_direction(geometric, 𝐩) -> SVector{3}
    chief_direction(camera::RadiometricCameraModel, 𝐩) -> SVector{3}

Unit chief direction d̂(𝐩) = π⁻¹(𝐩)/‖π⁻¹(𝐩)‖ of a sensor position ([`chief_ray`](@ref), normalized): the direction along which the
focus point 𝔣(𝐩) lies at the distance 1/t̂(𝐩) from the centre of projection. `π⁻¹` of a spline camera is a bicubic blend of unit
node directions and is not unit (≤ 2e-4 off inside the image circle on real lattices); the parametric models return unit vectors.
Dual-generic: when `π⁻¹` carries partials the normalisation projects them onto the tangent plane of d̂.
"""
@inline chief_direction(geometric, 𝐩::StaticVector{2}) = normalize(chief_ray(geometric, 𝐩))
@inline chief_direction(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = chief_direction(c.geometric, 𝐩)

"""
    inverse_focus_distance(geometric, focus::Focus, 𝐩)
    inverse_focus_distance(camera::RadiometricCameraModel, 𝐩)

The camera's inverse focus distance at the sensor position 𝐩 (the paper's `t̂(𝐩)`): the focus
surface's thin plate spline at 𝐩.
"""
@inline inverse_focus_distance(geometric, f::Focus, 𝐩::StaticVector{2}) = inverse_focus_distance(f, 𝐩)
@inline inverse_focus_distance(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = inverse_focus_distance(c.geometric, c.focus, 𝐩)

"""
    focus_point(geometric, focus::Focus, 𝐩) -> SVector{3}
    focus_point(camera::RadiometricCameraModel, 𝐩) -> SVector{3}

Focus point 𝔣(𝐩) = 𝔱(𝐩) d̂(𝐩) on the Petzval surface (the paper's `𝔣`), d̂ the UNIT chief direction (camera frame,
the centre of projection 𝔭 = 0): ‖𝔣(𝐩)‖ = 𝔱(𝐩) = 1/t̂(𝐩) exactly, for every lens class.
"""
@inline focus_point(geometric, f::Focus, 𝐩::StaticVector{2}) = inv(inverse_focus_distance(geometric, f, 𝐩)) * chief_direction(geometric, 𝐩)
@inline focus_point(c::RadiometricCameraModel, 𝐩::StaticVector{2}) = focus_point(c.geometric, c.focus, 𝐩)

"""
    aperture_direction(d̂, 𝐚, t̂) -> SVector{3}
    aperture_direction(geometric, focus::Focus, 𝐩, 𝐚) -> SVector{3}
    aperture_direction(geometric, 𝐩, 𝐚, t̂) -> SVector{3}

The radiometric back-projection on a camera's PARTS: the unit direction from the aperture point 𝐚 towards the focus point 𝔣(𝐩)
(camera frame), `normalize(d̂(𝐩) − t̂(𝐩) 𝐚)` with the unit chief direction d̂ = `chief_direction(geometric, 𝐩)` (regular for focus at
infinity). The first form is the implementation, on a unit chief direction `d̂` and an inverse focus distance `t̂` the caller
evaluated (once per sensor sample); the form with a trailing `t̂` takes it hoisted the same way. A camera, and any record holding a
camera's parts, answers VisualGeometryToolkitCore's `backproject(camera, 𝐩, 𝐚)` by forwarding here (below).
"""
@inline function aperture_direction(d̂::StaticVector{3}, 𝐚::StaticVector{3}, t̂val)
    d = d̂ - t̂val * 𝐚
    return d / sqrt(d[1]^2 + d[2]^2 + d[3]^2)
end
@inline aperture_direction(geometric, f::Focus, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}) =
    aperture_direction(chief_direction(geometric, 𝐩), 𝐚, inverse_focus_distance(geometric, f, 𝐩))
@inline aperture_direction(geometric, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}, t̂val) = aperture_direction(chief_direction(geometric, 𝐩), 𝐚, t̂val)

"""
    backproject(camera::RadiometricCameraModel, 𝐩, 𝐚[, t̂]) -> SVector{3}

The radiometric back-projection, the paper's `π̂⁻¹(𝐩, 𝐚)`: the unit direction of the ray of the sensor position
𝐩 from the aperture point 𝐚 (camera frame), towards the focus point 𝔣(𝐩) — a method of VisualGeometryToolkitCore's `backproject`
with the aperture point as its third argument ([`aperture_direction`](@ref) on the camera's parts). `backproject(camera, 𝐩, 𝔭)` is
the chief direction; `backproject(camera, 𝐩)` is the geometric camera's back-projection. With a trailing `t̂`, the inverse focus
distance the caller evaluated (hoisted, once per sensor sample).
"""
@inline backproject(c::RadiometricCameraModel, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}) = aperture_direction(c.geometric, c.focus, 𝐩, 𝐚)
@inline backproject(c::RadiometricCameraModel, 𝐩::StaticVector{2}, 𝐚::StaticVector{3}, t̂val) = aperture_direction(c.geometric, 𝐩, 𝐚, t̂val)
# the paper's notation: VisualGeometryToolkitCore's `backproject` itself (its three-argument methods are the radiometric ones)

"""
    world_ray(pose, 𝐚, d) -> (origin, direction)
    world_ray(camera::RadiometricCameraModel, pose, 𝐩, 𝐚) -> (origin, direction)

Ray of the sensor position 𝐩 through the aperture point 𝐚 of `camera` at `pose` (camera → world, VisualGeometryToolkitCore's
`EuclideanMap`), in world coordinates. The first form is the implementation: the ray from the aperture point 𝐚 along the
camera-frame direction `d` (an [`aperture_direction`](@ref)), moved by `pose` (a plain, unlabeled map, as a kernel holds it); the
camera's form takes any pose and reads it unlabeled.
"""
@inline world_ray(pose::EuclideanMap, 𝐚::StaticVector{3}, d::StaticVector{3}) = (pose(𝐚), pose.R * d)
@inline function world_ray(c::RadiometricCameraModel, pose::EuclideanMap, 𝐩::StaticVector{2}, 𝐚::StaticVector{3})
    return world_ray(unlabel(pose), 𝐚, backproject(c, 𝐩, 𝐚))
end

# `lens` is VisualGeometryToolkitCore's lens model of a geometric camera: a radiometric camera is refused by name with what to call
lens(::RadiometricCameraModel) = throw(ArgumentError(
    "`lens` is VisualGeometryToolkitCore's lens model of a geometric camera; a radiometric camera's geometric camera is " *
    "`geometric(camera)`, its lens model `lens(geometric(camera))`"))

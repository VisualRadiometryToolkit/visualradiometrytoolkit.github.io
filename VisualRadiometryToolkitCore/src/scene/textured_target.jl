# ---------------------------------------------------------------------------
# A textured target: a printed planar target as the radiometry sees it. Its GEOMETRY and its DESIGN are VisualGeometryToolkitCore's —
# a `PosedTarget` of a `PlanarTarget` whose `Canvas` is the printed page, and the canvas's `CanvasTexture` the printed image (its
# file, hash and the rectangle of the design chart it covers) — and this package attaches the target's APPEARANCE (`TexturedTarget`):
# the image's pixels (the albedo), the printed layout's edge map (the printed-edge model, printed_edge.jl), the design size in mm
# that scales the map, and the target's own state (target_state.jl: its warping, its printed edge, its in-plane print error).
#
#   target     VgtkCore.PosedTarget: the planar target (Core's design chart: x right, y up as the printed side is seen from the front,
#              metres) posed into the world (metres, plain numbers); its `canvas` holds the page and the printed image
#   quad       the page — the canvas texture's rectangle (the canvas's when it has no texture) — as a Core `Quad` with the texture's
#              chart: corner at the image's top-left, e_u along +x, e_v along −y (the image rows), n = e_u × e_v; a ray off the page
#              misses (NaN)
#   chart      𝐛 = chart(quad, 𝐱) ./ size ∈ [0, 1]² — the image fraction: 𝐛₁ → columns, 𝐛₂ → rows from the top
#   size       the page's (width, height) [m] (the rectangle of the canvas texture; the kernels' isbits copy)
#   facing     +1 or −1: the side of the quad's normal the cameras look at (`with_facing`; the design's +z until then); the target's normal for the
#              shading and the warping is facing · n
#   texture    albedo ρ_c(𝐛), (H_t, W_t, 3) array: the printed image's pixels (linear)
#   sdf        optional distance map of the printed layout (H_s × W_s): the signed distance [mm] from every texel centre to the
#              nearest ink edge of the design (+ on paper, − in ink); when set, the albedo is the printed-edge model
#              (printed_edge.jl)
#   page_mm    the design size [mm] the distance map spans along e_u and e_v (the scale of `sdf` and of the edge parameters; 0 without one)
#   state      the target's own state (`TargetState`: warping h, printed edge, in-plane print error), by value
#   𝔟          the target's centre (`centroid`)
# ---------------------------------------------------------------------------

"""
    TexturedTarget{T}

A printed planar target as the radiometry sees it: VisualGeometryToolkitCore's posed planar target (its geometry and design: `target`,
whose canvas is the page; the `quad` its rays meet) with the printed appearance attached — the image's pixels, the optional distance map
of the printed layout and its size in mm — and the target's own state (`state`, a [`TargetState`](@ref): its warping, its printed
edge, its in-plane print error; the plane, printed as designed, unless stated). See the file header for the chart convention. On a
device the posed target itself stays behind (`nothing`): the kernels read only the quad, the appearance and the state, which is
isbits and replaced by value ([`with_state`](@ref)).
"""
struct TexturedTarget{T, Q <: VgtkCore.Quad{T}, A3 <: AbstractArray{T, 3}, S <: Union{Nothing, AbstractMatrix{T}}, P, Wp, St <: TargetState}
    target::P                    # VgtkCore.PosedTarget{<:VgtkCore.PlanarTarget} with a Canvas (host), `nothing` on a device
    quad::Q                      # the page: the canvas texture's rectangle, rows down
    size::SVector{2, T}          # the page along e_u, e_v [m]
    facing::T                    # ±1: the side of the quad's normal the cameras see
    texture::A3
    sdf::S
    page_mm::SVector{2, T}
    warping::Wp                  # VgtkCore.MappedSurface: the flat warping's surface, the parts a render rebuilds with h (target_warping.jl)
    state::St                    # the target's own state, by value, in its own element type (target_state.jl)
end
Adapt.adapt_structure(to, b::TexturedTarget) =
    TexturedTarget(nothing, b.quad, b.size, b.facing, adapt(to, b.texture), adapt(to, b.sdf), b.page_mm, adapt(to, b.warping), b.state)

# the posed target's pose as a plain map: a textured target is posed exactly, so a pose that carries an uncertainty (an estimate's)
# is refused by name
_plain_pose(target::VgtkCore.PosedTarget) = _plain_pose(VgtkCore.pose(target))
_plain_pose(pose::EuclideanMap) = pose
_plain_pose(pose) = throw(ArgumentError("TexturedTarget: the target's pose is a $(nameof(typeof(pose))), not a plain EuclideanMap — a textured " *
                                        "target is posed exactly: give the pose's value"))

"""
    TexturedTarget([T = Float64,] target::PosedTarget, texture; sdf = nothing, page_mm = nothing)

The textured target of Core's posed planar `target` — e.g. a calibration session's target record (VisualGeometryToolkitIO's rig/v6:
its canvas and the canvas texture), or a bare board posed in the world, `PosedTarget(Board(Size2(width = 2m, height = 2m)), pose)` —
with the image's pixels `texture` laid over the canvas texture's rectangle, else the canvas's, else the board's. A physical target
(lengths) is taken in metres at entry. The board faces the side its cameras are on: a camera's state or render orients it by its
pose ([`with_facing`](@ref)); until then it faces the design's +z, the printed side of Core's design chart. `sdf` + `page_mm`: the
distance map of the printed layout and the design size it spans in mm ([`with_sdf`](@ref); printed_edge.jl).
"""
TexturedTarget(target::VgtkCore.PosedTarget, texture::AbstractArray{<:Real, 3}; kw...) = TexturedTarget(Float64, target, texture; kw...)
function TexturedTarget(::Type{T}, target::VgtkCore.PosedTarget, texture::AbstractArray{<:Real, 3}; sdf = nothing,
                        page_mm = nothing) where {T}
    target = VgtkCore.has_units(target) ? VgtkCore.ustrip(VgtkCore.m, target) : target   # metres at the boundary, plain inside
    r = _page_rect(VgtkCore.model(target))                                 # the page in the design chart (metres, y up)
    W, H = Float64(r.widths[1]), Float64(r.widths[2])
    pose = _plain_pose(target)
    R = SMatrix{3, 3, Float64}(VgtkCore.rotation(pose))
    o = SVector{3, Float64}(pose(SVector(Float64(r.origin[1]), Float64(r.origin[2]) + H, 0.0)))    # the image's top-left corner
    frame = hcat(R[:, 1], -R[:, 2], -R[:, 3])                                                       # e_u = +x, e_v = −y, n = e_u × e_v
    quad = VgtkCore.Quad{T}(VgtkCore.Quad(o, frame, VgtkCore.Rect2{Float64}(0.0, 0.0, W, H)))
    (sdf === nothing) == (page_mm === nothing) || throw(ArgumentError("TexturedTarget: `sdf` needs `page_mm` (and vice versa)"))
    sd = sdf === nothing ? nothing : Matrix{T}(sdf)
    pm = page_mm === nothing ? zero(SVector{2, T}) : SVector{2, T}(page_mm)
    # the design's +z (the printed side, seen from the front with x right and y up) is −n: facing −1
    return TexturedTarget(target, quad, SVector{2, T}(W, H), -one(T), Array{T, 3}(texture), sd, pm, convert_eltype(T, flat_surface(target)), TargetState{T}())
end
"""
    TexturedTarget(𝐨, 𝐮_B, 𝐯_B, texture; sdf = nothing, page_mm = nothing, design = :printed_page)

The page with its image's top-left corner `𝐨` and edges `𝐮_B` (along the image's columns), `𝐯_B` (along its rows) (world, metres;
orthogonal — `𝐯_B` is orthogonalised to rounding): Core's planar target `design` whose board and canvas are the page (design chart
x along `𝐮_B`, y against `𝐯_B`, the origin at the page's lower-left corner `𝐨 + 𝐯_B`), posed into the world, with the `texture` laid
over it; the form of a page measured in the world. Its facing is the posed target's ([`with_facing`](@ref)). `sdf` + `page_mm`: the
distance map of the printed layout and the page size in mm ([`with_sdf`](@ref); printed_edge.jl).
"""
function TexturedTarget(𝐨::AbstractVector, 𝐮_B::AbstractVector, 𝐯_B::AbstractVector, texture::AbstractArray{<:Real, 3};
                       sdf = nothing, page_mm = nothing, design::Symbol = :printed_page)
    T = float(promote_type(eltype(𝐨), eltype(𝐮_B), eltype(𝐯_B)))
    o = SVector{3, Float64}(𝐨); u = SVector{3, Float64}(𝐮_B); v = SVector{3, Float64}(𝐯_B)
    W = norm(u); e_u = u / W
    v⊥ = v - dot(v, e_u) * e_u
    H = norm(v⊥); e_v = v⊥ / H
    n = cross(e_u, e_v)
    abs(dot(v, e_u)) <= 1e-9 * W * norm(v) || throw(ArgumentError("TexturedTarget: the page edges 𝐮_B, 𝐯_B are not orthogonal"))
    page = VgtkCore.Size2(W, H)
    pose = VgtkCore.EuclideanMap(VgtkCore.Rotations.RotMatrix{3, Float64}(hcat(e_u, -e_v, -n)), o + H * e_v)   # design → world
    target = VgtkCore.PosedTarget(VgtkCore.PlanarTarget(design; board = VgtkCore.Board(page), canvas = VgtkCore.Canvas(page)), pose)
    return TexturedTarget(T, target, texture; sdf, page_mm)
end

"""
    with_facing(board::TexturedTarget, viewpoint) -> TexturedTarget

The board facing the side of its page that the world point `viewpoint` (a camera centre) is on: its normal for the shading and the
warping ([`board_normal`](@ref)) points towards it. A camera's calibration state and its render orient the board by the camera's
pose; a caller that builds a board's geometry before the poses exist orients it with them.
"""
function with_facing(b::TexturedTarget{T}, viewpoint::AbstractVector) where {T}
    o = world_point(b, SVector(0.0, 0.0))
    side = dot(SVector{3, Float64}(viewpoint) - SVector{3, Float64}(o), SVector{3, Float64}(VgtkCore.normal(b.quad))) < 0 ? -one(T) : one(T)
    return TexturedTarget(b.target, b.quad, b.size, side, b.texture, b.sdf, b.page_mm, b.warping, b.state)
end

"""The board with the distance map `sdf` (`H_s × W_s`, signed distance [mm] to the nearest ink edge of the design, + on paper)
of a page of `page_mm` = (width, height) mm: its albedo becomes the printed-edge model (`edge_albedo`)."""
with_sdf(b::TexturedTarget{T}, sdf::AbstractMatrix, page_mm) where {T} =
    TexturedTarget(b.target, b.quad, b.size, b.facing, b.texture, Matrix{T}(sdf), SVector{2, T}(page_mm), b.warping, b.state)

"""The board's normal on the cameras' side, `facing · (e_u × e_v)`: the shading frame's normal and the direction of the warping h."""
@inline board_normal(b::TexturedTarget) = b.facing * VgtkCore.normal(b.quad)

"""World point of chart coordinates 𝐛 (Core's `surface_point` of the quad at the design point 𝐛 ⊙ size)."""
@inline world_point(b::TexturedTarget, 𝐛::StaticVector{2}) = VgtkCore.surface_point(b.quad, SVector(𝐛[1] * b.size[1], 𝐛[2] * b.size[2]))
"""
    centroid(b::TexturedTarget) -> SVector{3}

The target's centre, the page's (world): VisualGeometryToolkitCore's `centroid` of a shape: the paper's `𝔟`.
"""
centroid(b::TexturedTarget) = world_point(b, SVector(0.5, 0.5))
"""
    EnvironmentLight(map, board::TexturedTarget, poses)

The light of the radiance `map` (a [`SphericalHarmonicMap`](@ref)) on the sphere about the board's centre (VisualGeometryToolkitCore's `centroid`)
that holds every camera centre of `poses` (camera → world) and every corner of the page, so that every light ray from the page
leaves the sphere (no ray of a board point falls back to its closest point, [`exit_direction`](@ref)).
"""
function EnvironmentLight(map, b::TexturedTarget, poses::AbstractVector)
    𝐛 = centroid(b)
    cameras = maximum(norm(SVector{3}(p.t) - SVector{3}(𝐛)) for p in poses)
    return EnvironmentLight(map, 𝐛, max(cameras, maximum(norm(c - 𝐛) for c in corners(b))))
end

"""The page's corners: `𝐨`, `𝐨 + 𝐮_B`, `𝐨 + 𝐮_B + 𝐯_B`, `𝐨 + 𝐯_B`."""
corners(b::TexturedTarget) = (world_point(b, SVector(0.0, 0.0)), world_point(b, SVector(1.0, 0.0)), world_point(b, SVector(1.0, 1.0)),
                             world_point(b, SVector(0.0, 1.0)))
"""
    texture_size(b::TexturedTarget) -> (H_t, W_t)

The size of the board's texture in texels, rows first (`size(texture)[1:2]`).
"""
texture_size(b::TexturedTarget) = (size(b.texture, 1), size(b.texture, 2))

"""
    intersect_board(b, 𝐨_ray, 𝐝) -> (s, 𝐱)

Where the ray `𝐱 = 𝐨_ray + s 𝐝` (s ≥ 0) meets the page: Core's `intersection` with the board's quad (`ray_plane_intersection`'s
arithmetic). A ray that misses — parallel to the page, hitting behind its origin or off the page — gives `s` and `𝐱` NaN.
"""
@inline intersect_board(b::TexturedTarget, o::StaticVector{3}, d::StaticVector{3}) = VgtkCore.intersection(b.quad, o, d)

"""
    board_plane_hit(b, 𝐨_ray, 𝐝) -> (s, 𝐱)

Where the ray meets the PLANE of the page, on or off the page, in front or behind (Core's `ray_plane_intersection` on the quad's
plane): the self-check's board residuals, which measure the detections' rays wherever they land.
"""
@inline function board_plane_hit(b::TexturedTarget, o::StaticVector{3}, d::StaticVector{3})
    x, y, z, s = VgtkCore.ray_plane_intersection(b.quad.plane, o, d[1], d[2], d[3])
    return s, SVector(x, y, z)
end

# the page chart 𝐛 ∈ ℝ² (the page fraction) of a world point on the target: VisualGeometryToolkitCore's `chart` of the quad over the
# page size (a method of its contract generic on this package's type)
@inline function chart(b::TexturedTarget, 𝐱::StaticVector{3})
    c = VgtkCore.chart(b.quad, 𝐱)
    return SVector(c[1] / b.size[1], c[2] / b.size[2])
end

"""`true` if 𝐛 lies inside the board with padding `δ` (chart units)."""
@inline inside(𝐛::StaticVector{2}, δ = zero(eltype(𝐛))) = (δ <= 𝐛[1] <= 1 - δ) && (δ <= 𝐛[2] <= 1 - δ)

"""
    albedo(b::TexturedTarget, 𝐛) -> SVector{3}

Albedo (RGB) of the target's texture at the page chart 𝐛, the paper's `ρ_c(𝐛)`: VisualGeometryToolkitCore's
`bilinear_sample` (half-texel convention, clamped to the edge, a non-finite 𝐛 reads the corner texel; dual-safe: the texel is chosen
on the value part). [`printed_albedo`](@ref) is the albedo of the target as printed (the printed-edge model where it has a distance map).
"""
@inline albedo(b::TexturedTarget, 𝐛::StaticVector{2}) = VgtkCore.bilinear_sample(b.texture, Val(3), 𝐛)

# --- the target's state: read, replaced by value (the arrays untouched), and its parts replaced on the target
"""
    with_state(b::TexturedTarget, state::TargetState) -> TexturedTarget

The target with its state replaced, by value: the same page, texture and distance map (no array is copied or converted), the state
in ITS element type — dual numbers of a Jacobian, Float32 on a device.
"""
@inline with_state(b::TexturedTarget, state::TargetState) = @set b.state = state
@inline with_h(b::TexturedTarget, h) = with_state(b, with_h(b.state, h))
@inline with_edge(b::TexturedTarget, edge) = with_state(b, with_edge(b.state, edge))
@inline with_inplane(b::TexturedTarget, θ) = with_state(b, with_inplane(b.state, θ))
@inline height_on(b::TexturedTarget) = height_on(b.state)
@inline inplane_on(b::TexturedTarget) = inplane_on(b.state)
@inline ink_spread(b::TexturedTarget) = ink_spread(b.state)
@inline print_blur(b::TexturedTarget) = print_blur(b.state)

# the target in another element type (VisualGeometryToolkitCore's `convert_eltype`: Float32 for a device kernel): element types only,
# no re-sampling; the posed target (host) is kept as it is
function convert_eltype(::Type{T}, b::TexturedTarget) where {T}
    sd = b.sdf === nothing ? nothing : T.(b.sdf)
    return TexturedTarget(b.target, VgtkCore.Quad{T}(b.quad), SVector{2, T}(b.size), T(b.facing), T.(b.texture), sd, SVector{2, T}(b.page_mm),
                          convert_eltype(T, b.warping), convert_eltype(T, b.state))
end

# =============================================================================
# Vignetting: the part of a camera that attenuates light across the sensor
# =============================================================================
#
#   * `NoVignetting` — the absent vignetting, V ≡ 1: the default of a
#                      radiometric camera.
#
# The vignetting fields (the tensor-product and radial B-spline fields, the
# log-domain field) and their protocol are VisualGeometryToolkitCore's today
# and move here (docs/design/inventory.md). `NoVignetting` is born here and
# subtypes VisualGeometryToolkitCore's `AbstractVignetting` until the abstract
# type itself moves, so it is accepted today wherever a vignetting is.
# =============================================================================

"""
    NoVignetting()

The absent vignetting: `V ≡ 1` everywhere on the sensor. It has no parameters,
so it adds no coordinates to a calibration and no columns to a Jacobian, and it
is the default vignetting of a radiometric camera: a camera that is not given
one attenuates nothing.

It is a singleton that compiles away. Called at a sensor point, `v(u)` (and
`v(u, f)` with the point's ray), it returns `true`, the multiplicative identity
of every number type: `true * x === x` for a float, a dual number or a
quantity, so a kernel that multiplies by the value is compiled to one that does
not multiply. A kernel can also take a method for `::NoVignetting` and skip the
factor altogether.

The parameter protocol of VisualGeometryToolkitCore answers for it with nothing:
`parameter_vector` is empty, `parameter_names` is `()`, and `with_parameters`
takes the empty vector and returns it unchanged.

# Examples
```jldoctest
julia> using StaticArrays: SVector

julia> v = NoVignetting();

julia> v(SVector(1200.0, 800.0))
true

julia> v(SVector(1200.0, 800.0)) * 0.25
0.25

julia> length(parameter_vector(v))
0
```
"""
struct NoVignetting <: AbstractVignetting end

@inline (::NoVignetting)(::StaticVector{2}) = true
@inline (::NoVignetting)(::StaticVector{2}, ::StaticVector{3}) = true

parameter_vector(::NoVignetting) = SVector{0, Float64}()
parameter_names(::NoVignetting) = ()
function with_parameters(v::NoVignetting, θ::AbstractVector)
    isempty(θ) || throw(ArgumentError("NoVignetting takes no parameters; got $(length(θ))"))
    return v
end

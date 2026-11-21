# The kinds

Each kind is the serialization of one VisualRadiometryToolkitCore type. The
two verbs are VisualGeometryToolkitIO's, `load(T, path)` and `save(path,
value)`; this package adds the methods for its types, so a reader reaches
every kind of the stack through the same two calls
(`import VisualGeometryToolkitIO as VgtkIO`).

| Kind | Value | Read | Written |
|---|---|---|---|
| `vgio/vignetting/v2.0` | an `AbstractVignetting`: a `TensorProductVignetting` (its knots stated), a `RadialVignetting` (its `chart` always stated) or a `LogVignetting`, positions in any registered pixel frame (`units.pixel`); rebuilt bit for bit | `VgtkIO.load(AbstractVignetting, path)` | `VgtkIO.save(path, v)` |
| `vgio/environment_light/v2.0` | an `EnvironmentLight` of a `SphericalHarmonicMap`: centre and radius in `units.length` (a plain light refused), coefficients per channel in `units.radiance`, the degree `max_degree` and the basis convention stated (`real_orthonormal_no_condon_shortley`) | `VgtkIO.load(EnvironmentLight, path)` | `VgtkIO.save(path, light; length_unit = mm)` |
| `vgio/radial_profile/v1.0` | a `BinnedRadialProfile`: a measured profile binned by its chart's coordinate (a flat field by field angle), its chart's centre and radius in `units.pixel`, its edges in `units.angle` | `VgtkIO.load(BinnedRadialProfile, path)` | `VgtkIO.save(path, p)` |

`VgtkIO.validate(path)` checks a file of any of these kinds against its table
and returns the kind's name (`"vignetting"`, `"environment_light"`,
`"radial_profile"`).

## Where the kinds came from

The three kinds were VisualGeometryToolkitIO's up to its 0.10 and moved here
with the types they hold. Their schema names did not change, so a file written
before the move loads here as it is. A `vgio/vignetting/v1` or
`vgio/environment_light/v1` file (VisualGeometryToolkitIO 0.9's) reads through
its version step, and `VisualGeometryToolkitIO.vgio_migrate(path)` rewrites
one once. Without this package loaded, VisualGeometryToolkitIO refuses a file
of these kinds by name and names this package.

## Embedding a body in another record

Each body is a value on VisualGeometryToolkitIO's `VgioStyle`: a record of
another package that holds a vignetting, a light or a radial profile writes it
with `JSON.lower(style, value)` (or leaves the value in the record for the
style to lower) and reads it with `JSON.lift(style, AbstractVignetting,
record)`, `JSON.lift(style, EnvironmentLight, record)` or `JSON.lift(style,
BinnedRadialProfile, record)`. A kind that states its table
(`VisualGeometryToolkitIO.KindSpec`) names the body's table:
[`VIGNETTING_BODY`](@ref VisualRadiometryToolkitIO.VIGNETTING_BODY),
[`ENVIRONMENT_LIGHT_BODY`](@ref VisualRadiometryToolkitIO.ENVIRONMENT_LIGHT_BODY),
[`RADIAL_PROFILE_BODY`](@ref VisualRadiometryToolkitIO.RADIAL_PROFILE_BODY).
The version step of another package's record that embeds a
`vgio/vignetting/v1` body runs
[`migrate_vignetting_body`](@ref VisualRadiometryToolkitIO.migrate_vignetting_body).

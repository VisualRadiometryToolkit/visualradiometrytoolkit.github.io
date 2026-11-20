# API Reference

```@meta
CurrentModule = VisualRadiometryToolkitIO
```

```@docs
VisualRadiometryToolkitIO
```

## Reading and writing

The kinds are read and written by VisualGeometryToolkitIO's two verbs, `load`
and `save` (public there, not exported: `import VisualGeometryToolkitIO as
VgtkIO`); this package adds the methods for its types.

```@docs
VgtkIO.save(::AbstractString, ::AbstractVignetting)
VgtkIO.load(::Type{AbstractVignetting}, ::AbstractString)
VgtkIO.save(::AbstractString, ::EnvironmentLight{<:SphericalHarmonicMap})
VgtkIO.load(::Type{EnvironmentLight}, ::AbstractString)
VgtkIO.save(::AbstractString, ::BinnedRadialProfile)
VgtkIO.load(::Type{BinnedRadialProfile}, ::AbstractString)
```

## The kinds and their tables

```@docs
VIGNETTING_KIND
ENVIRONMENT_LIGHT_KIND
RADIAL_PROFILE_KIND
VIGNETTING_BODY
ENVIRONMENT_LIGHT_BODY
RADIAL_PROFILE_BODY
migrate_vignetting_body
json_schemas
```

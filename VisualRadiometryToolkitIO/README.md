# VisualRadiometryToolkitIO.jl

[![CI](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/actions/workflows/CI.yml)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitIO/dev/)

The file formats of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the radiometric types of [VisualRadiometryToolkitCore](../VisualRadiometryToolkitCore)
saved and loaded as self-describing files, in the envelope and under the schema
rules of VisualGeometryToolkitIO.

**Under construction.** The package is at the placeholder version 0.0.1 and is
not in a registry.

## The kinds

Each kind is the serialization of one VisualRadiometryToolkitCore type, read
and written by VisualGeometryToolkitIO's two verbs (`load(T, path)`,
`save(path, value)`), to which this package adds its methods:

| Kind | Value |
|---|---|
| `vgio/vignetting/v2.0` | an `AbstractVignetting`: a tensor-product, radial or log field |
| `vgio/environment_light/v2.0` | an `EnvironmentLight` of a `SphericalHarmonicMap` |
| `vgio/radial_profile/v1.0` | a `BinnedRadialProfile`, a measured radial profile |

The kinds were VisualGeometryToolkitIO's up to its 0.10 and moved here with the
types they hold. Their schema names did not change: a file written before the
move loads here as it is, and an earlier version reads through its version
step.

## License

MIT. See [LICENSE](LICENSE).

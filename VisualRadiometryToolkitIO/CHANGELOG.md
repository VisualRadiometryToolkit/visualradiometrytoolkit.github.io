# VisualRadiometryToolkitIO changelog

## 0.1.2

On VisualRadiometryToolkitCore 0.2 (`[compat]` `"0.2"`), whose breaking changes (a textured target's facing, its centre's
name) touch no record of this package. No source changed.

## 0.1.1

On VisualGeometryToolkitCore 0.13 and VisualGeometryToolkitIO 0.11.2 (`[compat]` `"0.13"`, `"0.11.2"`): Core's
release adds the artifact store and removes the spherical spline and the dilogarithm, which this package does not
use. The tests read a body nested in another record and edit a record into one its reader refuses through
VisualGeometryToolkitIO's `nested_roundtrip` and `edited_copy` (0.11.2), no copy of their own. No source changed.

## 0.1.0

The first release. The package holds the file kinds of VisualRadiometryToolkitCore's vignetting fields, environment
lights and measured radial profiles. The kinds came from VisualGeometryToolkitIO (its 0.10 and earlier held them; its
0.11.0 refuses a file of these kinds and names this package), with the types they hold, which came from
VisualGeometryToolkitCore to VisualRadiometryToolkitCore. No schema name and no file changes: every file written
before the move loads here. Migration from VisualGeometryToolkitIO 0.10: load this package; the calls are the same
(`load(AbstractVignetting, path)`, `save(path, v)`, with the types imported from VisualRadiometryToolkitCore). It
depends on VisualGeometryToolkitCore 0.12, VisualGeometryToolkitIO 0.11 and VisualRadiometryToolkitCore 0.1.

- **`vgio/vignetting/v2.0`** (an `AbstractVignetting`), **`vgio/environment_light/v2.0`** (an `EnvironmentLight` of a
  `SphericalHarmonicMap`) and **`vgio/radial_profile/v1.0`** (a `BinnedRadialProfile`): each kind's table
  (`VIGNETTING_KIND`, `ENVIRONMENT_LIGHT_KIND`, `RADIAL_PROFILE_KIND`: VisualGeometryToolkitIO `KindSpec`s), its
  `load` and `save` (methods of VisualGeometryToolkitIO's two verbs), the bodies' `JSON.lower`/`JSON.lift` on
  `VgioStyle`, and the bodies' tables for a record of another package that embeds one (`VIGNETTING_BODY`,
  `ENVIRONMENT_LIGHT_BODY`, `RADIAL_PROFILE_BODY`).
- The version steps of `vgio/vignetting/v1` and `vgio/environment_light/v1` (VisualGeometryToolkitIO 0.9's files),
  read on load and rewritten by `vgio_migrate`; `migrate_vignetting_body`, the vignetting body's step for a record of
  another package that embeds a v1 body.
- `validate_record` methods, so VisualGeometryToolkitIO's `validate` and calibration manifests check these kinds'
  files.
- The kinds' JSON Schemas (`json_schemas()`, published under `docs/src/schemas`; their `$id` below
  `https://visualradiometrytoolkit.github.io/schemas/`).

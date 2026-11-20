# VisualRadiometryToolkitIO changelog

## 0.0.1 (placeholder, not registered)

The radiometric file kinds move here from VisualGeometryToolkitIO (its 0.10 held them; its 0.11 drops them), with the
types they hold, which moved from VisualGeometryToolkitCore to VisualRadiometryToolkitCore. No schema name and no file
changes: every file written before the move loads here.

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

# VisualRadiometryToolkitCore changelog

## 0.0.1 (placeholder, not registered)

The package skeleton.

### Added

- `NoVignetting`: the absent vignetting, `V ≡ 1`. A singleton with no
  parameters (no calibration coordinates, no Jacobian columns) whose value is
  `true`, so a kernel that multiplies by it is compiled to one that does not.
  It subtypes VisualGeometryToolkitCore's `AbstractVignetting` and answers its
  parameter protocol with nothing.
- The planned layout, as commented `include`s in
  `src/VisualRadiometryToolkitCore.jl` and the manual's Design page.

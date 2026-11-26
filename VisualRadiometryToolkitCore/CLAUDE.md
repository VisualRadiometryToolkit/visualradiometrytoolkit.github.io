# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this package. The workspace's rules are in the repository root's
`CLAUDE.md`; read both.

VisualRadiometryToolkitCore: the types of a radiometric camera, a camera of
VisualGeometryToolkitCore together with the parts that decide how much light a
pixel collects (its focus surface, its aperture radius, its vignetting), and
of the scene it sees (an environment light, a material, a textured target).

## The rules of this package

- **Radiometry lifts geometry.** The package depends on
  VisualGeometryToolkitCore and on nothing else of the stack
  (`configs/stack_dependencies.toml`). It never asks VisualGeometryToolkitCore
  to know about it.
- **The vignetting is an abstract type with an absent default, `NoVignetting`.**
  It is a singleton with no parameters (no calibration coordinates, no Jacobian
  columns) whose value is `true`; a kernel never tests a vignetting against
  `nothing`. The manual's Design page states the rules.
- **One implementation of each camera-frame map, on the parts it reads.**
  `RadiometricCameraModel` and any record holding the same parts forward to it
  (`CONTRACT_GENERICS`).
- **Public names are descriptive ASCII**; the paper's symbols appear in
  docstrings and comments only, never as a binding (no aliases).
- **Methods on VisualGeometryToolkitCore's functions land on its contract
  generics only** (`VisualGeometryToolkitCore.CONTRACT_GENERICS`; the quality
  gate enforces it). A protocol that is not a contract there is not extended
  from here: it moves here first.
- **What moves here is removed from where it was**, by name, with its
  replacement. Nothing is kept in two places (`DUPLICATION.toml` at the root
  has no entry).

## Testing

ReTestItems: `Pkg.test()` runs every item; `Pkg.test(; test_args =
["vignetting"])` filters items by name; `RETESTITEMS_NWORKERS=0` runs serially
for debugging. Check the reported total. The quality gates are
VisualGeometryToolkitCore's (`test/quality_tests.jl`); this package holds no
copy of them.

## Stack Conventions

The canonical text lives once, in VisualGeometryToolkitCore's `conventions/`
folder (it ships with the package:
`VisualGeometryToolkitCore.conventions_dir()`; in its repository,
`VisualGeometryToolkitCore/conventions/`). This package follows it and carries
no copy.

## Git Commit Conventions

- **NEVER** add "Co-Authored-By: Claude" or similar AI attribution to commit messages
- **NEVER** add a "Generated with Claude Code" footer or similar

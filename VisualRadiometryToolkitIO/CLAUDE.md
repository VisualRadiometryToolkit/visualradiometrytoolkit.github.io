# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this package. The workspace's rules are in the repository root's
`CLAUDE.md`; read both.

VisualRadiometryToolkitIO: the file formats of the Visual Radiometry Toolkit,
the radiometric types of VisualRadiometryToolkitCore as self-describing files.
Under construction: version 0.0.1 is a placeholder, the module is empty and the
package is not registered.

## The rules of this package

- **The envelope and the schema rules are VisualGeometryToolkitIO's.** A kind
  here is written in that envelope and versioned by those rules (every earlier
  schema version a published file holds is read; only the current one is
  written). They are not restated or reimplemented here.
- **A kind that moves here keeps its name and its bytes.** A file written
  before the move loads after it; the move changes which package reads and
  writes the kind, never the file.
- **Dependencies arrive with the code that uses them** (an unused dependency
  fails the quality gates). The package may depend on
  VisualRadiometryToolkitCore, VisualGeometryToolkitCore and
  VisualGeometryToolkitIO, and on nothing else of the stack.

## Testing

ReTestItems: `Pkg.test()` runs every item; `RETESTITEMS_NWORKERS=0` runs
serially for debugging. Check the reported total. The quality gates are
VisualGeometryToolkitCore's (`test/quality_tests.jl`).

## Stack Conventions

The canonical text lives once, in VisualGeometryToolkitCore's `conventions/`
folder (`VisualGeometryToolkitCore.conventions_dir()`). This package follows it
and carries no copy.

## Git Commit Conventions

- **NEVER** add "Co-Authored-By: Claude" or similar AI attribution to commit messages
- **NEVER** add a "Generated with Claude Code" footer or similar

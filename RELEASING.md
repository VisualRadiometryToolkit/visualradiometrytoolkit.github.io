# Releasing

**Nothing is released yet.** VisualRadiometryToolkitCore is at the placeholder
version 0.0.1 and is in no registry; `ci/registration_lint.jl` warns on the
placeholder and fails if a registry already holds the package. This file states
how the first release and every later one are made.

## The registries

The stack's rule holds here: every package is registered from a subdirectory of
this repository in exactly ONE registry.

- **First: [CauRegistry](https://github.com/prittjam/CauRegistry.jl)**, the
  stack's own registry. VisualRadiometryToolkitCore's first registration
  (0.1.0) is there, with `subdir = "VisualRadiometryToolkitCore"`.
  RadiometricCamera (in CauRegistry) depends on it from there in its next minor
  release.
- **Later: General**, in dependency order: VisualRadiometryToolkitCore first,
  then RadiometricCamera. A package leaves CauRegistry when its first General
  version merges (its folder and its `Registry.toml` line removed in one
  registry commit, after General holds every version CauRegistry had).

One registry per package means one release step and no version that is in one
registry and not the other; nothing installed breaks when an entry moves, since
a Manifest records UUID, version and tree hash, never the registry. Users add
CauRegistry only for the packages not yet in General.

The Visual Geometry Toolkit packages this workspace depends on are taken from
the registry that holds them (General), never from a path: `[sources]` in this
repository name its own packages only.

## Before the first release

Once, by the owner:

1. The `DOCUMENTER_KEY` secret: an ssh deploy key with write access (the
   public half a deploy key of this repository, the private half the secret).
   TagBot pushes the release tag with it, so the tag push triggers `Site.yml`
   (a push made with the workflow token triggers nothing), and CompatHelper's
   pull requests trigger CI with it.
2. Codecov: enable the repository (uploads are by OIDC; no token secret).
3. Zenodo, if the toolkit is to have a DOI: as for the Visual Geometry Toolkit
   (ONE concept DOI for the repository; then `doi:` in `CITATION.cff`).
4. CI, where it must resolve a package that is only in CauRegistry: add the
   registry before instantiating (today every dependency is in General).

## A release

1. All checks green on `main` (CI, Site, Links).
2. Local pre-release checks on the release machine (no hosted runner can do them):
   - GPU items, once the package has any: `CUDA_VISIBLE_DEVICES=0 julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test()'`. Never device 1.
   - Strict run: `Pkg.test(; julia_args = ["--depwarn=error"])` for each package.
   - The fresh-clone gate: clone, resolve the workspace from scratch, `Pkg.test()`.
3. Bump `version` in `<Package>/Project.toml` (the first release: 0.0.1 → 0.1.0;
   `ci/registration_lint.jl` then applies the first-registration rules); widen
   dependents' compat in the same commit if the bump is breaking. Raise every
   compat floor to the gated environment's resolution.
4. A package not yet in General: register it in CauRegistry from a clean
   checkout of that commit (`LocalRegistry.register("<Package>"; registry =
   "CauRegistry", repo = "https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io.git")`;
   the subdirectory is detected) and push the registry.
5. A package in General: comment on that commit `@JuliaRegistrator register
   subdir=<Package>` (one comment per package, dependency order), with release
   notes for a breaking version (AutoMerge requires them). A dependent's
   release waits for the merge. New packages wait three days in General.
6. TagBot tags `<Package>-v<version>` and creates the GitHub release; the tag
   push builds that package's docs into `gh-pages/<Package>/v<version>` and
   redeploys the site. (TagBot follows General; for a CauRegistry-only release
   tag `<Package>-v<version>` on the release commit by hand.)

## The migration releases

The radiometric types of VisualGeometryToolkitCore and the camera model of
RadiometricCamera move here in a release cascade, stated in
[docs/design/inventory.md](docs/design/inventory.md): this package's release
that holds a type comes first (CauRegistry); the release of the package that
held it retires it by name with its replacement; the dependants' releases
follow. Zero duplication is the rule: code is moved, never copied, and
`DUPLICATION.toml` holds no exception for moved code. A type is never released
in two packages as two owners.

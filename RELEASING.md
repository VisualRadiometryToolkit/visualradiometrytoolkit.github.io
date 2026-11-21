# Releasing

Every package is registered in the [General](https://github.com/JuliaRegistries/General)
registry from its subdirectory of this repository (`subdir = "<Package>"`),
each with its own version. A package's first registration is version 0.1.0;
the registration lint (CLAUDE.md, "Commands") applies the first-registration
rules to a package General does not hold; a package at the placeholder
version of `WORKSPACE.toml` is under construction and is not registered.

The Visual Geometry Toolkit packages this workspace depends on are taken from
General, never from a path or a git revision: `[sources]` in this repository
name its own packages only (the root project's, and a test or docs project's
`{path = ".."}`).

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

## A release

1. All checks green on `main` (CI, Site, Links).
2. Local pre-release checks on the release machine (no hosted runner can do them):
   - GPU items, once the package has any: `CUDA_VISIBLE_DEVICES=0 julia --project=VisualRadiometryToolkitCore -e 'using Pkg; Pkg.test()'`. Never device 1.
   - Strict run: `Pkg.test(; julia_args = ["--depwarn=error"])` for each package.
   - The fresh-clone gate: clone, resolve the workspace from scratch, `Pkg.test()`.
3. Bump `version` in `<Package>/Project.toml`; widen dependents' compat in the
   same commit if the bump is breaking. Raise every compat floor to the gated
   environment's resolution.
4. Run the registration lint (for a package General does not hold yet, without
   `--subsequent`).
5. Comment on that commit `@JuliaRegistrator register subdir=<Package>` (one
   comment per package, in dependency order: VisualRadiometryToolkitCore, then
   VisualRadiometryToolkitIO), with release notes for a breaking version
   (AutoMerge requires them). A dependent's release waits for the merge. A new
   package waits three days in General.
6. TagBot tags `<Package>-v<version>` and creates the GitHub release; the tag
   push builds that package's docs into `gh-pages/<Package>/v<version>` and
   redeploys the site. No tag is made by hand before the registration.

## Moving a type between packages

A type is never released in two packages as two owners. The release of the
package that receives it comes first; the release of the package that held it
retires it by name with its replacement; the dependants' releases follow.
`DUPLICATION.toml` has no entry for a moved type.

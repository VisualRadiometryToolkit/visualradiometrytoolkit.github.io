# Design

This page states the design the package is being built to. What exists today
is marked; the rest is planned, and its code lives for now in
VisualGeometryToolkitCore and in
[RadiometricCamera](https://realcamerasareradiometric.github.io). The item by
item inventory and the order of the moves are in the repository,
[`docs/design/inventory.md`](https://github.com/VisualRadiometryToolkit/visualradiometrytoolkit.github.io/blob/main/docs/design/inventory.md).

## Radiometry lifts geometry

A geometric camera answers *where*: which pixel a scene point projects to, and
which ray a pixel sees. A radiometric camera answers *how much*: the light a
pixel collects along those rays. The second question needs the first, and not
the reverse, so the dependency runs one way:

- a radiometric camera **holds** a geometric camera of
  VisualGeometryToolkitCore, any of them, unchanged;
- this package depends on VisualGeometryToolkitCore; nothing in the Visual
  Geometry Toolkit depends on this package;
- the conventions are the Visual Geometry Toolkit's and are not restated here.

RAW reading and the sensor's *noise* model stay in VisualGeometryToolkitCore:
feature detectors, which are geometry, read RAW photosites and weigh them by
their noise. The sensor's *response* (what maps collected light to a digital
value) is radiometry and belongs here.

## A camera is made of parts, and every part can be absent

Each thing that changes how much light a pixel collects is a **part** of the
camera: an abstract type, with the concrete models as its subtypes. Every part
has an absent default, named `No…`:

| part | what it models | absent default | status |
|---|---|---|---|
| vignetting | attenuation across the sensor | [`NoVignetting`](@ref): `V ≡ 1` | **here**; the fields move from VisualGeometryToolkitCore |
| aperture | the opening that admits light | a point aperture (a pinhole) | planned, from RadiometricCamera |
| focus | where the camera is in focus | everything in focus | planned, from RadiometricCamera |
| blur | the point spread on the sensor | no blur | planned, from VisualGeometryToolkitCore |
| response | collected light to digital value | the identity | planned |

The rules every absent default follows, with [`NoVignetting`](@ref) as the
first instance:

1. **A singleton.** It has no fields and no type parameters, so a camera that
   holds it is no larger, and it is `isbits` on every backend.
2. **No parameters.** Its parameter vector is empty: it adds no coordinates to
   a calibration and no columns to a Jacobian. A calibration of a camera with
   an absent part is the calibration of a camera without that part, not one
   with a part held fixed.
3. **It compiles away.** A kernel reaches a part through the part's type, so
   the absent default is resolved by dispatch at compile time: its value is
   the identity of the operation it enters (`true` for a factor), or the
   kernel has a method for it that omits the term. No branch is taken at run
   time and no `nothing` is tested.
4. **It is the default.** A radiometric camera built from a geometric camera
   alone has every part absent, and is that geometric camera: it renders what
   a pinhole renderer renders.

A model is therefore extended by adding a part or a subtype of a part. A camera
that does not use the extension pays nothing for it, and code written before
the extension keeps its meaning.

## The layout

`src/VisualRadiometryToolkitCore.jl` lists the files; a planned file is a
commented `include` with one line saying what it will hold:

- `camera/`: the parts and the radiometric camera that holds them;
- `scene/`: lights and materials;
- `radiance/`: the integrals a pixel's value is (over the aperture and the
  pixel's footprint) and the kernels that evaluate them, one implementation
  for the CPU and every GPU backend.

Estimation (calibrating a radiometric camera from images) is not core: it is
planned as a later package of this workspace, as VisualGeometryToolkitEstimation
is to VisualGeometryToolkitCore.

# Design

This page states the design the package is built to. What exists today is
marked. The generic radiometric types of
[RadiometricCamera](https://realcamerasareradiometric.github.io) (the code of
the paper "Real Cameras are Radiometric") and of VisualGeometryToolkitCore are
here; the paper's calibration method stays in RadiometricCamera. The item by
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
| vignetting | attenuation across the sensor | [`NoVignetting`](@ref): `V ≡ 1` | **here**, with the B-spline fields |
| aperture | the opening that admits light | a point aperture (a pinhole) | **here** as the camera's aperture radius and its quadrature ([`VisualRadiometryToolkitCore.ApertureQuadrature`](@ref)); the absent default is planned |
| focus | where the camera is in focus | everything in focus | **here** as the focus surface ([`VisualRadiometryToolkitCore.Focus`](@ref)); the absent default is planned |
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

[`RadiometricCameraModel`](@ref) composed from a geometric camera has
[`NoVignetting`](@ref) unless a vignetting is stated; a field to estimate (a
[`TensorProductVignetting`](@ref), a [`RadialVignetting`](@ref)) is asked for
by name, by the calibration that estimates it.

## One implementation, on the parts it reads

The camera-frame maps of a radiometric camera (the unit chief direction, the
focus point `𝔣`, the back-projection from the aperture `π̂⁻¹`, a ray in the
world) are implemented once, on the parts they read: the geometric camera and
the focus surface. [`RadiometricCameraModel`](@ref) forwards to them, and so
does any other record that holds the same parts (a renderer's per-photograph
record in a kernel's element type): a one-line method, never a second body. A
geometric camera enters through one function,
[`VisualRadiometryToolkitCore.chief_ray`](@ref), which every
VisualGeometryToolkitCore camera answers; it and the forwarded maps are this
package's `CONTRACT_GENERICS`, the functions another package may add methods to.

A model is therefore extended by adding a part or a subtype of a part. A camera
that does not use the extension pays nothing for it, and code written before
the extension keeps its meaning.

## The layout

`src/VisualRadiometryToolkitCore.jl` lists the files:

- `sensor/`: sensor positions and pixels, and the quadrature rules of the
  integrals a pixel's value is (over the pixel's footprint and the aperture);
- `camera/`: the parts (vignetting, focus) and the radiometric camera that
  holds them, with its back-projection from the aperture;
- `scene/`: lights and materials.

The kernels that evaluate a pixel's flux against a scene are their owner's
(RadiometricCamera's, for its printed calibration target); they call these
types on the CPU and on every GPU backend.

Estimation (calibrating a radiometric camera from images) is not core: it is
planned as a later package of this workspace, as VisualGeometryToolkitEstimation
is to VisualGeometryToolkitCore.

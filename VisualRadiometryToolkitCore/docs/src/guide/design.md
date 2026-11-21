# Design

This page states the design of the package. Its types came from two places:
the vignetting fields, the measured radial profile and the environment light
were VisualGeometryToolkitCore's (up to its 0.11); the radiometric camera, the
focus surface, the quadrature rules, the material and the textured target were
[RadiometricCamera](https://realcamerasareradiometric.github.io)'s (the code of
the paper "Real Cameras are Radiometric"). The paper's calibration method
stays in RadiometricCamera.

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

RAW reading and the sensor's noise model are VisualGeometryToolkitCore's:
feature detectors, which are geometry, read RAW photosites and weigh them by
their noise.

## A camera is one object, made of four parts

A [`RadiometricCameraModel`](@ref) holds the geometric camera and the three
things that change how much light a pixel collects:

| part | what it is | how it is stated |
|---|---|---|
| `geometric` | the geometric camera: any VisualGeometryToolkitCore camera bounded by its image | the constructor's argument |
| `focus` | the focus surface, a [`VisualRadiometryToolkitCore.Focus`](@ref): the inverse focus distance along each chief ray, a thin plate spline over the sensor | a `Focus`, or a distance in metres (the surface focused at that distance everywhere) |
| `aperture_radius` | the radius of the aperture disc, in metres; its quadrature is a [`VisualRadiometryToolkitCore.ApertureQuadrature`](@ref) | a number; it has no default, because it is a physical statement about the camera |
| `vignetting` | the attenuation across the sensor, an [`AbstractVignetting`](@ref) | a field, or nothing: the default is [`NoVignetting`](@ref) |

Each part is replaced by value (`with_geometric`, `with_focus`,
`with_aperture_radius`, `with_vignetting`); the image size is the geometric
camera's and is stated once.

## The absent vignetting

The vignetting is an abstract type, and its default is absent:
[`NoVignetting`](@ref), `V ≡ 1`. It follows four rules:

1. **A singleton.** It has no fields and no type parameters, so a camera that
   holds it is no larger, and it is `isbits` on every backend.
2. **No parameters.** Its parameter vector is empty: it adds no coordinates to
   a calibration and no columns to a Jacobian. A calibration of a camera
   without a vignetting is not one with a vignetting held fixed.
3. **It compiles away.** A kernel reaches the vignetting through its type, so
   the absent one is resolved by dispatch at compile time: its value is
   `true`, the identity of the product it enters. No branch is taken at run
   time and no `nothing` is tested.
4. **It is the default.** [`RadiometricCameraModel`](@ref) composed from a
   geometric camera has [`NoVignetting`](@ref) unless a vignetting is stated;
   a field to estimate (a [`TensorProductVignetting`](@ref), a
   [`RadialVignetting`](@ref)) is asked for by name, by the calibration that
   estimates it.

A vignetting model of another package is a subtype of
[`AbstractVignetting`](@ref). A camera that does not use it pays nothing for
it, and code written before it keeps its meaning.

## One implementation, on the parts it reads

The camera-frame maps of a radiometric camera (the unit chief direction, the
focus point, the back-projection from the aperture, a ray in the
world) are implemented once, on the parts they read: the geometric camera and
the focus surface. [`RadiometricCameraModel`](@ref) forwards to them, and so
does any other record that holds the same parts (a renderer's per-photograph
record in a kernel's element type): a one-line method, never a second body. A
geometric camera enters through one function,
[`VisualRadiometryToolkitCore.chief_ray`](@ref), which every
VisualGeometryToolkitCore camera answers; it and the forwarded maps are this
package's `CONTRACT_GENERICS`, the functions another package may add methods to.

## The layout

`src/VisualRadiometryToolkitCore.jl` lists the files:

- `sensor/`: sensor positions and pixels, and the quadrature rules of the
  integrals a pixel's value is (over the pixel's footprint and the aperture);
- `camera/`: the vignetting fields, the focus surface and the radiometric
  camera that holds them, with its back-projection from the aperture;
- `scene/`: the environment light, the material, and the textured target with
  its state, its warping and its printed-edge model.

The kernels that evaluate a pixel's flux against a scene are their owner's
(RadiometricCamera's, for its printed calibration target); they call these
types on the CPU and on a GPU. Calibrating a radiometric camera from images is
not in this package either: the paper's calibration is RadiometricCamera's.

## A textured target holds its own state

A [`TexturedTarget`](@ref) is a posed planar target of
VisualGeometryToolkitCore with its printed appearance. Its geometry and its
design stay VisualGeometryToolkitCore's; what a calibration learns about one
printed target (the warping of the page, the printed edge, the in-plane print
error) is the target's own state, a field of it. The state is isbits and
replaced by value, in its own element type: a renderer keeps the target's
arrays on a device and gives the target the numbers it differentiates. There
is no scene type: a render takes a camera, a pose and a target, and the image
size is the camera's.

# VisualRadiometryToolkitIO.jl

The file formats of the [Visual Radiometry Toolkit](https://visualradiometrytoolkit.github.io):
the radiometric types of
[VisualRadiometryToolkitCore](https://visualradiometrytoolkit.github.io/VisualRadiometryToolkitCore/)
saved and loaded as self-describing files, in the envelope and under the
schema rules of
[VisualGeometryToolkitIO](https://visualgeometrytoolkit.github.io/VisualGeometryToolkitIO/)
(one envelope that declares units and conventions; every earlier schema
version a published file holds still loads).

!!! warning "Under construction"
    The package is an empty skeleton at the placeholder version 0.0.1 and is
    not in a registry. The radiometric file kinds (vignetting, environment
    light, radial profile) are VisualGeometryToolkitIO's today and move here
    with the types they hold.

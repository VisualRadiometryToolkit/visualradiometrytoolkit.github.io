# Shared fixture of the camera items. ReTestItems discovers `@testsetup` modules in `*_testsetups.jl` files; an item takes one with
# `setup = [Name]` and sees what it exports.

@testsetup module PixelCameras
    using StaticArrays: SMatrix
    import VisualGeometryToolkitCore as VgtkCore
    """`cam(lens, f, c, W, H; f_y = f)`: VisualGeometryToolkitCore's pixel camera of a `W × H` image — K with the focal lengths `f`,
    `f_y` and the principal point `c` in COLMAP pixels over `lens` — bounded by the image's extent."""
    cam(lens, f, c, W, H; f_y = f) =
        VgtkCore.BoundedCamera(VgtkCore.CameraModel(VgtkCore.LogicalIntrinsics(VgtkCore.CameraCalibrationMat(SMatrix{3, 3}(f, 0, 0, 0, f_y, 0, c[1], c[2], 1))), lens),
                               VgtkCore.Size2(Int(W), Int(H)))
    export cam
end

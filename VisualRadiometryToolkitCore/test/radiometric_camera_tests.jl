# The radiometric camera as one value (camera/radiometric_camera.jl): a geometric camera with its focus surface, aperture radius and
# vignetting, and its camera-frame maps. Moved with the code from the model parts of RadiometricCamera's
# test/unit/camera_model_tests.jl and the back-projection part of its geometry_tests.jl.

@testitem "radiometric camera: one object, its parts, its back-projection" setup = [PixelCameras] begin
    using Test
    using VisualRadiometryToolkitCore: Focus, geometric, focus, aperture_radius, with_geometric, with_focus, with_aperture_radius,
                                       with_vignetting, chief_ray, chief_direction, center_of_projection, focus_point, aperture_direction, world_ray,
                                       inverse_focus_distance, focus_distance, n_nodes, 𝔭, 𝔣, π̂⁻¹, t̂, 𝔱
    using StaticArrays: SVector, SMatrix
    using LinearAlgebra: I, norm, normalize
    import ForwardDiff
    import VisualGeometryToolkitCore as VgtkCore

    W = H = 24
    lens = cam(VgtkCore.Lens(VgtkCore.DoubleSphere(0.25, 0.4)), 30.912, (12.24, 11.52), W, H)
    foc = Focus(3, 1.5, W, H)
    vig = TensorProductVignetting((4, 4), VgtkCore.Rect(0, 0, W, H); degree = 2)
    c = RadiometricCameraModel(lens, foc, 0.0386, vig)
    @test with_vignetting(c, vig).vignetting === vig
    # the camera composed from its geometric camera: the focus surface (a distance: focused there everywhere), the aperture radius and
    # the vignetting added; the image size is the geometric camera's, stated once
    @test RadiometricCameraModel(lens; focus = foc, aperture_radius = 0.0386, vignetting = vig) === c
    @test RadiometricCameraModel(lens; focus = 1.5, aperture_radius = 0.0386, vignetting = vig) === c
    @test Focus(lens, 1.5) == foc && n_nodes(Focus(lens, 2.0; n = 4)) == 16 && focus_distance(Focus(lens, 2.0; n = 4), SVector(5.0, 7.0)) ≈ 2.0
    @test_throws UndefKeywordError RadiometricCameraModel(lens; focus = 1.5)          # no default aperture: r is a physical statement
    @test isbits(c)                                                                     # the camera travels into a device kernel as it is
    # its parts read and replaced one at a time: the others are kept
    @test geometric(c) === lens && focus(c) === foc && aperture_radius(c) == 0.0386
    f2 = Focus(lens, 2.0); c2 = with_aperture_radius(with_focus(c, f2), 0.01)
    @test c2.focus === f2 && c2.aperture_radius == 0.01 && c2.geometric === lens && c2.vignetting === vig
    lens2 = cam(VgtkCore.Lens(VgtkCore.DoubleSphere(0.3, 0.4)), 30.912, (12.24, 11.52), W, H)
    @test with_geometric(c, lens2).geometric === lens2 && with_geometric(c, lens2).focus === foc
    @test VgtkCore.lens(geometric(c)) === VgtkCore.lens(lens)                          # the camera's lens model: of its geometric camera
    @test fieldnames(RadiometricCameraModel) == (:geometric, :focus, :aperture_radius, :vignetting)
    # the geometric camera's maps, forwarded
    @test VgtkCore.project(c, SVector(0.1, 0.0, 1.0)) == VgtkCore.project(lens, SVector(0.1, 0.0, 1.0))
    @test VgtkCore.backproject(c, SVector(5.0, 7.0)) == VgtkCore.backproject(lens, SVector(5.0, 7.0))

    # the camera-frame maps: one implementation on the parts, the camera forwards
    𝐩 = SVector(16.8, 9.6); 𝐚 = SVector(0.02, -0.01, 0.0)
    @test center_of_projection == SVector(0.0, 0.0, 0.0)
    # the paper's notation: public aliases of the same objects; π̂⁻¹ is VisualGeometryToolkitCore's `backproject` (its radiometric
    # methods take the aperture point as a third argument)
    @test 𝔭 === center_of_projection && 𝔣 === focus_point && t̂ === inverse_focus_distance && 𝔱 === focus_distance && π̂⁻¹ === VgtkCore.backproject
    @test VgtkCore.backproject(c, 𝐩, 𝐚) === aperture_direction(lens, foc, 𝐩, 𝐚) && VgtkCore.backproject(c, 𝐩) == VgtkCore.backproject(lens, 𝐩)
    # `lens` of a radiometric camera is refused by name: its geometric camera's is `lens(geometric(camera))`
    @test_throws "a radiometric camera's geometric camera is `geometric(camera)`, its lens model `lens(geometric(camera))`" VgtkCore.lens(c)
    @test VgtkCore.lens(geometric(c)) === VgtkCore.lens(lens)
    @test chief_ray(lens, 𝐩) == SVector{3}(VgtkCore.backproject(lens, 𝐩)) && chief_direction(lens, 𝐩) == normalize(chief_ray(lens, 𝐩))
    @test chief_direction(c, 𝐩) === chief_direction(lens, 𝐩)
    @test inverse_focus_distance(c, 𝐩) === inverse_focus_distance(lens, foc, 𝐩) === inverse_focus_distance(foc, 𝐩)                                   # the sensor chart: the surface at 𝐩
    @test focus_point(c, 𝐩) === focus_point(lens, foc, 𝐩) && norm(focus_point(c, 𝐩)) ≈ 1.5
    @test π̂⁻¹(c, 𝐩, 𝔭) ≈ chief_ray(lens, 𝐩)                                           # π̂⁻¹(𝐩, 𝔭) = π⁻¹(𝐩)
    @test π̂⁻¹(c, 𝐩, 𝐚) ≈ normalize(focus_point(c, 𝐩) - 𝐚)                                       # the (𝔣 − 𝐚)/‖𝔣 − 𝐚‖ form
    @test π̂⁻¹(c, 𝐩, 𝐚) === aperture_direction(lens, foc, 𝐩, 𝐚) === aperture_direction(chief_direction(lens, 𝐩), 𝐚, inverse_focus_distance(foc, 𝐩)) === π̂⁻¹(c, 𝐩, 𝐚, inverse_focus_distance(c, 𝐩)) === aperture_direction(lens, 𝐩, 𝐚, inverse_focus_distance(c, 𝐩))
    pose = VgtkCore.EuclideanMap(SMatrix{3, 3}(1.0I), SVector(0.0, 0.0, -1.5); check = false)
    o, d = world_ray(c, pose, 𝐩, 𝐚)
    @test o ≈ pose.t + pose.R * 𝐚 && norm(d) ≈ 1 && (o, d) == world_ray(VgtkCore.unlabel(pose), 𝐚, π̂⁻¹(c, 𝐩, 𝐚))
    # generic in the element type: a Float32 camera stays Float32, a dual sensor position carries its partials
    l32 = VgtkCore.convert_eltype(Float32, lens); f32 = VgtkCore.convert_eltype(Float32, foc)
    @test aperture_direction(l32, f32, SVector{2, Float32}(𝐩), SVector{3, Float32}(𝐚)) isa SVector{3, Float32}
    @test chief_direction(lens, SVector(ForwardDiff.Dual(16.8, 1.0), ForwardDiff.Dual(9.6, 0.0))) isa SVector{3, <:ForwardDiff.Dual}
    # another package's geometric camera answers `chief_ray` (a contract generic) and carries a radiometric camera
    @test chief_ray in VisualRadiometryToolkitCore.CONTRACT_GENERICS
end

@testitem "radiometric camera: NoVignetting is the default" setup = [PixelCameras] begin
    using Test
    using VisualRadiometryToolkitCore: Focus, with_vignetting, n_control_points, coefficient_jacobian
    using StaticArrays: SVector, SMatrix
    import VisualGeometryToolkitCore as VgtkCore

    lens = cam(VgtkCore.Lens(VgtkCore.DoubleSphere(0.25, 0.4)), 30.0, (12.0, 12.0), 24, 24)
    c = RadiometricCameraModel(lens; focus = 1.5, aperture_radius = 0.0386)
    # the composed camera has no vignetting unless one is stated: V ≡ 1, no parameters, nothing for a kernel to multiply by
    @test c.vignetting === NoVignetting() && c isa RadiometricCameraModel{<:Any, <:Any, Float64, NoVignetting}
    @test c.vignetting(SVector(5.0, 7.0)) === true && n_control_points(c.vignetting) == 0 && isempty(coefficient_jacobian(c.vignetting, SVector(5.0, 7.0)))
    @test isbits(c) && sizeof(c) == sizeof(RadiometricCameraModel(lens, c.focus, 0.0386, NoVignetting()))
    # a field to estimate is stated; the flat surface is V ≡ 1 too, with its nodes as parameters
    flat = TensorProductVignetting((4, 4), VgtkCore.Rect(0, 0, 24, 24); degree = 2)
    cf = with_vignetting(c, flat)
    @test cf.vignetting === flat && n_control_points(cf.vignetting) == 16 && cf.vignetting(SVector(5.0, 7.0)) ≈ 1
    @test with_vignetting(cf, NoVignetting()) === c
end

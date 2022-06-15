const Plane = @import("Plane.zig");

pub const Cuboid = @This();
planes: [6]Plane,

pub fn init(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
    l: f32,
) Cuboid {
    return .{
        .planes = .{
            Plane.init_y(x, y, z, w, l),
            Plane.init_z(x, y, z + l, w, h),
            Plane.init_x(x + w, y, z + l, w, h),
            Plane.init_z(x, y, z, w, h),
            Plane.init_x(x, y, z + l, w, h),
            Plane.init_y(x, y + h, z, w, l),
        },
    };
}

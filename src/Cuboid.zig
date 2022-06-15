const Vertex = @import("Vertex.zig");

pub const Cuboid = @This();
vertices: [6]Vertex,

pub fn init(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
    l: f32,
) Cube {
    return .{
        .vertices = .{
            Vertex.init_y(x, y, z, w, l),
            Vertex.init_z(x, y, z + l, w, h),
            Vertex.init_x(x + w, y, z + l, w, h),
            Vertex.init_z(x, y, z, w, h),
            Vertex.init_x(x, y, z + l, w, h),
            Vertex.init_y(x, y + h, z, w, l),
        },
    };
}

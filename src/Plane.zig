pub const Plane = @This();
area: [4][3]f32,

/// Creates plane that's aligned with the x-axis
pub fn init_x(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
) Plane {
    return .{ .area = .{
        .{ x, y, z },
        .{ x, y, z - l },
        .{ x, y + h, z - l },
        .{ x, y + h, z },
    } };
}

/// Creates plane that's aligned with the y-axis
pub fn init_y(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    l: f32,
) Plane {
    return .{ .area = .{
        .{ x, y, z },
        .{ x + w, y, z },
        .{ x + w, y, z - l },
        .{ x, y, z - l },
    } };
}

/// Creates plane that's aligned with the z-axis
pub fn init_z(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
) Plane {
    return .{ .area = .{
        .{ x, y, z },
        .{ x + w, y, z },
        .{ x + w, y + h, z },
        .{ x, y + h, z },
    } };
}

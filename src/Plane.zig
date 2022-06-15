const std = @import("std");

pub const Plane = @This();
area: [4][3]f32,
color: u32,

/// Creates plane that's aligned with the x-axis
pub fn init_x(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
    color: u32,
) Plane {
    return .{
        .area = .{
            .{ x, y, z },
            .{ x, y, z - w },
            .{ x, y + h, z - w },
            .{ x, y + h, z },
        },
        .color = color,
    };
}

/// Creates plane that's aligned with the y-axis
pub fn init_y(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    l: f32,
    color: u32,
) Plane {
    return .{
        .area = .{
            .{ x, y, z },
            .{ x + w, y, z },
            .{ x + w, y, z + l },
            .{ x, y, z + l },
        },
        .color = color,
    };
}

/// Creates plane that's aligned with the z-axis
pub fn init_z(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
    color: u32,
) Plane {
    return .{
        .area = .{
            .{ x, y, z },
            .{ x + w, y, z },
            .{ x + w, y + h, z },
            .{ x, y + h, z },
        },
        .color = color,
    };
}

/// Rotates vertex around another point by angle (degrees) in x-axis
fn rotate_vertex_x(vertex: *[3]f32, point: [3]f32, angle: f32) void {
    const radians = -angle * std.math.pi / 180;
    const y = vertex[1] - point[1];
    const z = vertex[2] - point[2];
    vertex[1] = @cos(radians) * y - @sin(radians) * z + point[1];
    vertex[2] = @sin(radians) * y + @cos(radians) * z + point[2];
}

/// Rotates vertex around another point by angle (degrees) in y-axis
fn rotate_vertex_y(vertex: *[3]f32, point: [3]f32, angle: f32) void {
    const radians = angle * std.math.pi / 180;
    const x = vertex[0] - point[0];
    const z = vertex[2] - point[2];
    vertex[0] = @cos(radians) * x - @sin(radians) * z + point[0];
    vertex[2] = @sin(radians) * x + @cos(radians) * z + point[2];
}

/// Rotates vertex around another point by angle (degrees) in z-axis
fn rotate_vertex_z(vertex: *[3]f32, point: [3]f32, angle: f32) void {
    const radians = -angle * std.math.pi / 180;
    const x = vertex[0] - point[0];
    const y = vertex[1] - point[1];
    vertex[0] = @cos(radians) * x - @sin(radians) * y + point[0];
    vertex[1] = @sin(radians) * x + @cos(radians) * y + point[1];
}

/// Rotate plane around another point by angle (degrees) in x-axis
pub fn rotate_x(self: *Plane, point: [3]f32, angle: f32) void {
    for (self.area) |*vertex| rotate_vertex_x(vertex, point, angle);
}

/// Rotate plane around another point by angle (degrees) in y-axis
pub fn rotate_y(self: *Plane, point: [3]f32, angle: f32) void {
    for (self.area) |*vertex| rotate_vertex_y(vertex, point, angle);
}

/// Rotate plane around another point by angle (degrees) in z-axis
pub fn rotate_z(self: *Plane, point: [3]f32, angle: f32) void {
    for (self.area) |*vertex| rotate_vertex_z(vertex, point, angle);
}

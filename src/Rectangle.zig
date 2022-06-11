const std = @import("std");
const c = @import("c.zig");

pub const Rectangle = @This();
area: [4][2]f32,
color: u32 = 0xFFFFFFFF,

pub fn init(x: f32, y: f32, w: f32, h: f32) Rectangle {
    return .{ .area = .{ .{ x, y }, .{ x + w, y }, .{ x + w, y + h }, .{ x, y + h } } };
}

/// Get center of rectangle
pub fn center(self: Rectangle) @Vector(2, f32) {
    return .{ self.area[0][0] + self.width() / 2, self.area[0][1] + self.height() / 2 };
}

/// Get width of rectangle
pub fn width(self: Rectangle) f32 {
    return self.area[1][0] - self.area[0][0];
}

/// Get height of rectangle
pub fn height(self: Rectangle) f32 {
    return self.area[2][1] - self.area[0][1];
}

/// Mirrors rectangle
pub fn mirror(self: *Rectangle) void {
    var temporary = self.area[0];
    self.area[0] = self.area[1];
    self.area[1] = temporary;
    temporary = self.area[2];
    self.area[2] = self.area[3];
    self.area[3] = temporary;
}

/// Rotates rectangle around point by angle (degrees)
pub fn rotate(self: *Rectangle, origo: [2]f32, angle: f32) void {
    const radians = angle * std.math.pi / 180;
    for (self.area) |*point| {
        const x = point[0] - origo[0];
        const y = point[1] - origo[1];
        point[0] = @cos(radians) * x - @sin(radians) * y + origo[0];
        point[1] = @sin(radians) * x + @cos(radians) * y + origo[1];
    }
}

/// Checks collision for axis aligned rectangles (no rotation)
pub fn aabb_collides(self: Rectangle, other: Rectangle) bool {
    const rx = self.area;
    const ry = other.area;
    return (rx[0][0] < ry[1][0] and rx[1][0] > ry[0][0] and rx[0][1] < ry[2][1] and rx[2][1] > ry[0][1]);
}

/// Checks collision for any bounding boxes (with rotation), returns relative displacement
pub fn diag_collides(self: Rectangle, other: Rectangle) ?@Vector(2, f32) {
    const rx = self.area;
    const ry = other.area;

    // Diagonals of rectangle
    var i: usize = 0;
    while (i < rx.len) : (i += 1) {
        const line = .{ self.center(), rx[i] };

        // Edges of other rectangle
        var j: usize = 0;
        while (j < ry.len) : (j += 1) {
            const edge = .{ ry[j], ry[(j + 1) % ry.len] };
            const h = (edge[1][0] - edge[0][0]) * (line[0][1] - line[1][1]) - (line[0][0] - line[1][0]) * (edge[1][1] - edge[0][1]);
            const t1: f32 = ((edge[0][1] - edge[1][1]) * (line[0][0] - edge[0][0]) + (edge[1][0] - edge[0][0]) * (line[0][1] - edge[0][1])) / h;
            const t2: f32 = ((line[0][1] - line[1][1]) * (line[0][0] - edge[0][0]) + (line[1][0] - line[0][0]) * (line[0][1] - edge[0][1])) / h;

            // If collision
            if (t1 >= 0 and t1 < 1 and t2 >= 0 and t2 < 1) {
                const delta = .{ (1 - t1) * (line[1][0] - line[0][0]), (1 - t1) * (line[1][1] - line[0][1]) };
                const hyp = @sqrt(delta[0] * delta[0] + delta[1] * delta[1]);
                return [2]f32{ delta[0] / hyp, delta[1] / hyp };
            }
        }
    }
    return null;
}

/// Checks collision for any bounding boxes and returns offset as [-1..1, -1..1]
pub fn offset_collides(self: Rectangle, other: Rectangle) ?@Vector(2, f32) {
    if (diag_collides(self, other)) |_| {
        const delta = center(self) - center(other);
        const hyp = @sqrt(delta[0] * delta[0] + delta[1] * delta[1]);
        return [2]f32{ delta[0] / hyp, delta[1] / hyp };
    } else return null;
}

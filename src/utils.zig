const std = @import("std");
const c = @import("c.zig");

pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

pub fn print(input: []const u8) void {
    _ = c.printf(@ptrCast([*c]const u8, input));
}

// Draw triangle from points and color
pub fn triangle(points: [3][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw square from points and color
pub fn square(points: [4][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw texture from points and texture coordinates using texture_id
pub fn texture(points: [4][2]f32, coords: [4][2]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    var i: u8 = 0;
    while (i < 4) {
        c.GX_Position2f32(points[i][0], points[i][1]);
        c.GX_TexCoord2f32(coords[i][0], coords[i][1]);
        i += 1;
    }
    c.GX_End();
}

/// Draw sprite.
/// Settings is an array of following: [x, y, width, height]
/// Size is an array of following: [texture_width, texture_height]
pub fn sprite(area: [4][2]f32, settings: [4]f32, size: [2]f32) void {
    const coords = rectangle(settings[0] / size[0], settings[1] / size[1], settings[2] / size[0], settings[3] / size[1]);
    texture(area, coords);
}

// Rectangle
pub fn rectangle(x: f32, y: f32, width: f32, height: f32) [4][2]f32 {
    return .{ .{ x, y }, .{ x + width, y }, .{ x + width, y + height }, .{ x, y + height } };
}

pub fn center(area: [4][2]f32) @Vector(2, f32) {
    const width = area[1][0] - area[0][0];
    const height = area[2][1] - area[0][1];
    return .{ area[0][0] + width / 2, area[0][1] + height / 2 };
}

// Mirrors area
pub fn mirror(area: *[4][2]f32) void {
    var temporary = area[0];
    area[0] = area[1];
    area[1] = temporary;
    temporary = area[2];
    area[2] = area[3];
    area[3] = temporary;
}

/// Rotates area around point by angle (degrees)
pub fn rotate(area: *[4][2]f32, origo: [2]f32, angle: f32) void {
    const radians = angle * std.math.pi / 180;
    for (area) |*point| {
        const x = point[0] - origo[0];
        const y = point[1] - origo[1];
        point[0] = @cos(radians) * x - @sin(radians) * y + origo[0];
        point[1] = @sin(radians) * x + @cos(radians) * y + origo[1];
    }
}

/// Checks collision for axis aligned bounding boxes (no rotation)
pub fn aabb_collides(rx: [4][2]f32, ry: [4][2]f32) bool {
    return (rx[0][0] < ry[1][0] and rx[1][0] > ry[0][0] and rx[0][1] < ry[2][1] and rx[2][1] > ry[0][1]);
}

/// Checks collision for any bounding boxes (with rotation), returns relative displacement
pub fn diag_collides(rx: [4][2]f32, ry: [4][2]f32) ?@Vector(2, f32) {
    // Diagonals of rectangle
    var i: usize = 0;
    while (i < rx.len) : (i += 1) {
        const line = .{ center(rx), rx[i] };

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

/// Checks collision for axis aligned bounding boxes (no rotation) and returns offset as [-1..1, -1..1]
pub fn offset_collides(rx: [4][2]f32, ry: [4][2]f32) ?@Vector(2, f32) {
    if (diag_collides(rx, ry)) |_| {
        const delta = center(ry) - center(rx);
        const hyp = @sqrt(delta[0] * delta[0] + delta[1] * delta[1]);
        return [2]f32{ delta[0] / hyp, delta[1] / hyp };
    } else return null;
}

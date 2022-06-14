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

/// Draw rectangle with color: 0xRRGGBBAA
pub fn draw(self: Rectangle, color: u32) void {
    // Turn off texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);

    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (self.area) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color1u32(color);
    }
    c.GX_End();

    // Turn on texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_MODULATE);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_DIRECT);
}

/// Draw border with color: 0xRRGGBBAA
pub fn draw_border(self: Rectangle, color: u32, stroke: u8) void {
    // Turn off texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);

    c.GX_SetLineWidth(stroke, c.GX_TO_ONE);
    c.GX_Begin(c.GX_LINESTRIP, c.GX_VTXFMT0, 5);
    for (self.area) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color1u32(color);
    }
    c.GX_Position2f32(self.area[0][0], self.area[0][1]);
    c.GX_Color1u32(color);
    c.GX_End();
    c.GX_SetLineWidth(stroke, c.GX_TO_ZERO);

    // Turn on texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_MODULATE);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_DIRECT);
}

/// Draw sprite with coords: [x, y, width, height] and size: [tpl_width, tpl_height]
pub fn draw_sprite(self: Rectangle, coords: [4]f32, size: [2]f32) void {
    const settings = Rectangle.init(coords[0] / size[0], coords[1] / size[1], coords[2] / size[0], coords[3] / size[1]);
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    var i: u8 = 0;
    while (i < 4) {
        c.GX_Position2f32(self.area[i][0], self.area[i][1]);
        c.GX_Color1u32(self.color);
        c.GX_TexCoord2f32(settings.area[i][0], settings.area[i][1]);
        i += 1;
    }
    c.GX_End();
}

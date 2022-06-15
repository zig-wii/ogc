const c = @import("c.zig");
const Plane = @import("Plane.zig");

pub const Cuboid = @This();
planes: [6]Plane,

// TODO: y-axis is currently in wrong direction, I think
pub fn init(
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    h: f32,
    l: f32,
) Cuboid {
    const color = 0xFFFFFFFF;
    return .{
        .planes = .{
            Plane.init_y(x, y, z, w, l, color),
            Plane.init_z(x, y, z + l, w, h, color),
            Plane.init_x(x + w, y, z + l, w, h, color),
            Plane.init_z(x, y, z, w, h, color),
            Plane.init_x(x, y, z + l, w, h, color),
            Plane.init_y(x, y + h, z, w, l, color),
        },
    };
}

// Size helpers
pub fn width(self: Cuboid) f32 {
    return self.planes[0].area[1][0] - self.planes[0].area[0][0];
}

pub fn height(self: Cuboid) f32 {
    return self.planes[1].area[0][1] - self.planes[1].area[3][1];
}

pub fn length(self: Cuboid) f32 {
    return self.planes[0].area[3][2] - self.planes[0].area[0][2];
}

pub fn center(self: Cuboid) [3]f32 {
    const x = self.planes[0].area[0][0] + self.width() / 2;
    const y = self.planes[0].area[0][1] - self.height() / 2;
    const z = self.planes[0].area[0][2] + self.length() / 2;
    return .{ x, y, z };
}

// Rotate helpers
pub fn rotate_x(self: *Cuboid, point: [3]f32, angle: f32) void {
    for (self.planes) |*plane| plane.rotate_x(point, angle);
}

pub fn rotate_y(self: *Cuboid, point: [3]f32, angle: f32) void {
    for (self.planes) |*plane| plane.rotate_y(point, angle);
}

pub fn rotate_z(self: *Cuboid, point: [3]f32, angle: f32) void {
    for (self.planes) |*plane| plane.rotate_z(point, angle);
}

// Colors and drawing
pub fn set_color(self: *Cuboid, color: u32) void {
    for (self.planes) |*plane| plane.color = color;
}

pub fn set_colors(self: *Cuboid, colors: [6]u32) void {
    var i: u8 = 0;
    while (i < 6) : (i += 1) self.planes[i].color = colors[i];
}

pub fn draw(self: Cuboid) void {
    // Turn off texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);

    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 24);
    for (self.planes) |plane| {
        for (plane.area) |point| {
            c.GX_Position3f32(point[0], point[1], point[2]);
            c.GX_Color1u32(plane.color);
        }
    }
    c.GX_End();

    // Turn on texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_MODULATE);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_DIRECT);
}

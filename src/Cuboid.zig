const c = @import("c.zig");
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
    color: u32,
) Cuboid {
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

pub fn set_colors(self: *Cuboid, colors: [6]u32) void {
    var i: u8 = 0;
    while (i < 6) : (i += 1) {
        self.planes[i].color = colors[i];
    }
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

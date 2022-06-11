const std = @import("std");
const c = @import("c.zig");
const Rectangle = @import("Rectangle.zig").Rectangle;

/// Creates a framebuffer from video mode
pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

/// Draw rectangle with color: 0xRRGGBBAA
pub fn rectangle(box: Rectangle, color: u32) void {
    // Turn off texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);

    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (box.area) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color1u32(color);
    }
    c.GX_End();

    // Turn on texturing
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_MODULATE);
    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_DIRECT);
}

/// Draw sprite with coords: [x, y, width, height] and size: [tpl_width, tpl_height]
pub fn sprite(box: Rectangle, coords: [4]f32, size: [2]f32) void {
    const settings = Rectangle.init(coords[0] / size[0], coords[1] / size[1], coords[2] / size[0], coords[3] / size[1]);
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    var i: u8 = 0;
    while (i < 4) {
        c.GX_Position2f32(box.area[i][0], box.area[i][1]);
        c.GX_Color1u32(box.color);
        c.GX_TexCoord2f32(settings.area[i][0], settings.area[i][1]);
        i += 1;
    }
    c.GX_End();
}

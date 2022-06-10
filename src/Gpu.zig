const std = @import("std");
const c = @import("c.zig");

const Gpu = @This();
vertexes: [8]?Vertex,

const Vertex = union(enum) {
    shape,
    texture: *c.GXTexObj,
};

pub fn init() Gpu {
    return .{ .vertexes = .{null} ** 8 };
}

/// Loads TPL from path.
pub fn load_tpl(self: *Gpu, comptime path: []const u8) void {
    // Data lives on forever, same as object
    const data = &struct {
        var bytes = @embedFile(path).*;
    }.bytes;
    var sprite: c.TPLFile = undefined;
    var object: c.GXTexObj = undefined;
    _ = c.TPL_OpenTPLFromMemory(&sprite, data, data.len);
    _ = c.TPL_GetTexture(&sprite, 0, &object);
    self.load_texture(&object);
}

/// Load texture into register by finding an empty slot.
fn load_texture(self: *Gpu, texture: *c.GXTexObj) void {
    for (self.vertexes) |*vertex, i| {
        if (vertex.* == null) {
            // Delete cache
            c.GX_InvVtxCache();

            // Load texture with GX
            const index = @intCast(u8, i);
            c.GX_LoadTexObj(texture, index);
            vertex.* = Vertex{ .texture = texture };

            // Setup graphics pipeline for texture
            c.GX_SetNumTevStages(index + 1);
            c.GX_SetNumChans(index + 1);
            c.GX_SetNumTexGens(index + 1);

            // 0  = GX_VTXFMT0
            // 0  = GX_TEVSTAGE0
            // 0  = GX_TEXCOORD0
            // 0  = GX_TEXMAP0
            // 4  = GX_TG_TEX0
            // 13 = GX_VA_TEX0
            c.GX_SetVtxAttrFmt(index, c.GX_VA_POS, c.GX_POS_XY, c.GX_F32, 0);
            c.GX_SetVtxAttrFmt(index, index + 13, c.GX_TEX_ST, c.GX_F32, 0);
            c.GX_SetTevOrder(index, index, index, c.GX_COLOR0A0);
            c.GX_SetTexCoordGen(index, c.GX_TG_MTX2x4, index + 4, c.GX_IDENTITY);
            c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_DIRECT);
            c.GX_SetVtxDesc(index + 13, c.GX_DIRECT);

            // Return after setup
            break;
        }
    }
}

// Loads appropiate settings for shapes
pub fn load_shapes(self: *Gpu) void {
    for (self.vertexes) |*vertex, i| {
        if (vertex.* == null) {
            // Delete cache
            c.GX_InvVtxCache();

            // Load shapes
            const index = @intCast(u8, i);
            vertex.* = .shape;

            // Setup graphics pipeline
            c.GX_SetNumTevStages(index + 1);
            c.GX_SetNumChans(index + 1);
            c.GX_SetNumTexGens(index + 1);

            c.GX_SetVtxAttrFmt(index, c.GX_VA_POS, c.GX_POS_XY, c.GX_F32, 0);
            c.GX_SetVtxAttrFmt(index, c.GX_VA_CLR0, c.GX_CLR_RGBA, c.GX_RGB8, 0);
            c.GX_SetTevOrder(index, c.GX_TEXCOORDNULL, c.GX_TEXMAP_NULL, c.GX_COLOR0A0);
            c.GX_SetTevOp(index, c.GX_PASSCLR);
            c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_DIRECT);
            c.GX_SetVtxDesc(c.GX_VA_CLR0, c.GX_DIRECT);
        }
    }
}

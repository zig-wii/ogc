const c = @import("c.zig");
const utils = @import("utils.zig");

const Video = @This();
mode: *c.GXRModeObj,
framebuffers: [2]*anyopaque,
index: u8,
perspective: c.Mtx44 = undefined,

pub fn init() Video {
    c.VIDEO_Init();
    var mode: *c.GXRModeObj = c.VIDEO_GetPreferredMode(null);
    var fbs: [2]*anyopaque = .{ utils.framebuffer(mode), utils.framebuffer(mode) };
    var fbi: u8 = 0;
    c.VIDEO_Configure(mode);
    c.VIDEO_SetNextFramebuffer(fbs[fbi]);
    c.VIDEO_SetBlack(false);
    c.VIDEO_Flush();

    const fifo_size: u32 = 256 * 1024;
    const buffer: [fifo_size]u32 = undefined;
    var fifo_buffer = c.MEM_K0_TO_K1(&buffer[0]) orelse unreachable;

    _ = c.GX_Init(fifo_buffer, fifo_size);
    c.GX_SetViewport(0, 0, @intToFloat(f32, mode.fbWidth), @intToFloat(f32, mode.efbHeight), 0, 1);

    const y_scale = c.GX_GetYScaleFactor(mode.xfbHeight, mode.efbHeight);
    _ = c.GX_SetDispCopyYScale(y_scale);

    c.GX_SetDispCopySrc(0, 0, mode.fbWidth, mode.efbHeight);
    c.GX_SetDispCopyDst(mode.fbWidth, mode.xfbHeight);
    c.GX_SetCopyFilter(mode.aa, &mode.sample_pattern, c.GX_TRUE, &mode.vfilter);
    c.GX_SetFieldMode(mode.field_rendering, @boolToInt(mode.viHeight == 2 * mode.xfbHeight));

    if (mode.aa != 0) c.GX_SetPixelFmt(c.GX_PF_RGB565_Z16, c.GX_ZC_LINEAR) else c.GX_SetPixelFmt(c.GX_PF_RGB8_Z24, c.GX_ZC_LINEAR);

    c.GX_SetCullMode(c.GX_CULL_NONE);
    c.GX_CopyDisp(fbs[fbi], c.GX_TRUE);
    c.GX_SetDispCopyGamma(c.GX_GM_1_0);

    // Set perspective matrix
    var perspective: c.Mtx44 = undefined;
    c.guOrtho(&perspective, 0, 479, 0, 639, 0, 320);
    c.GX_LoadProjectionMtx(&perspective, c.GX_ORTHOGRAPHIC);

    return Video{ .mode = mode, .framebuffers = fbs, .index = fbi, .perspective = perspective };
}

pub fn start(self: *Video) void {
    c.GX_SetViewport(0, 0, @intToFloat(f32, self.mode.fbWidth), @intToFloat(f32, self.mode.efbHeight), 0, 1);
}

pub fn camera(self: *Video, x: f32, y: f32) void {
    c.guOrtho(&self.perspective, y, y + 479, x, x + 639, 0, 320);
    c.GX_LoadProjectionMtx(&self.perspective, c.GX_ORTHOGRAPHIC);
}

pub fn finish(self: *Video) void {
    c.GX_DrawDone();
    self.index ^= 1;
    c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);
    c.GX_SetBlendMode(c.GX_BM_BLEND, c.GX_BL_SRCALPHA, c.GX_BL_INVSRCALPHA, c.GX_LO_CLEAR);
    c.GX_SetAlphaUpdate(c.GX_TRUE);
    c.GX_SetColorUpdate(c.GX_TRUE);
    c.GX_CopyDisp(self.framebuffers[self.index], c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(self.framebuffers[self.index]);
    c.VIDEO_Flush();
    c.VIDEO_WaitVSync();
}

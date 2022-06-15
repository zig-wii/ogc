pub const c = @import("c.zig");
pub const Pad = @import("Pad.zig");
pub const Video = @import("Video.zig");
pub const Rectangle = @import("Rectangle.zig");

/// Creates a framebuffer from video mode
pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

pub fn start(function: fn (*Video) anyerror!void, display: Video.Display) void {
    Pad.init();
    var video = Video.init(display);
    function(&video) catch |err| @panic(@errorName(err));
}

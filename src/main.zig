pub const c = @import("c.zig");
pub const Pad = @import("Pad.zig");
pub const Video = @import("Video.zig");
pub const Rectangle = @import("Rectangle.zig");
pub const Cuboid = @import("Cuboid.zig");
pub const Plane = @import("Plane.zig");

/// Creates a framebuffer from video mode
pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

pub fn start(function: *const fn (*Video) anyerror!void, comptime display: Video.Display) void {
    Pad.init();
    var video = Video.init(display);
    function(&video) catch |err| @panic(@errorName(err));
}

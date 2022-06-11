pub const c = @import("c.zig");
pub const utils = @import("utils.zig");
pub const Pad = @import("Pad.zig");
pub const Video = @import("Video.zig");
pub const Rectangle = @import("Rectangle.zig");

pub fn start(function: fn (*Video) anyerror!void) void {
    Pad.init();
    var video = Video.init();
    function(&video) catch |err| @panic(@errorName(err));
}

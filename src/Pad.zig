const std = @import("std");
const c = @import("c.zig");

pub fn init() void {
    _ = c.PAD_Init();
}

/// Update pads and return which controllers are connected
pub fn update() [4]bool {
    const connected = c.PAD_ScanPads();
    var controllers = [4]bool{ false, false, false, false };
    for (&controllers, 0..) |*controller, i| {
        if (connected & std.math.shl(u32, 1, i) != 0) {
            controller.* = true;
        }
    }
    return controllers;
}

/// Gamecube buttons
const Button = enum(u32) {
    left = c.PAD_BUTTON_LEFT,
    right = c.PAD_BUTTON_RIGHT,
    down = c.PAD_BUTTON_DOWN,
    up = c.PAD_BUTTON_UP,
    trigger_z = c.PAD_TRIGGER_Z,
    trigger_r = c.PAD_TRIGGER_R,
    trigger_l = c.PAD_TRIGGER_L,
    a = c.PAD_BUTTON_A,
    b = c.PAD_BUTTON_B,
    x = c.PAD_BUTTON_X,
    y = c.PAD_BUTTON_Y,
    start = c.PAD_BUTTON_START,
};

/// Check if button is up
pub fn button_up(button: Button, player: usize) bool {
    return (c.PAD_ButtonsUp(@intCast(i32, player)) & @enumToInt(button) != 0);
}

/// Check if button is pressed
pub fn button_down(button: Button, player: usize) bool {
    return (c.PAD_ButtonsDown(@intCast(i32, player)) & @enumToInt(button) != 0);
}

/// Check if button is held
pub fn button_held(button: Button, player: usize) bool {
    return (c.PAD_ButtonsHeld(@intCast(i32, player)) & @enumToInt(button) != 0);
}

/// Returns horizontal direction of c-stick
pub fn sub_stick_x(player: usize) f32 {
    return @intToFloat(f32, c.PAD_SubStickX(@intCast(i32, player))) / 128;
}

/// Returns vertical direction of c-stick
pub fn sub_stick_y(player: usize) f32 {
    return @intToFloat(f32, c.PAD_SubStickY(@intCast(i32, player))) / 128;
}

/// Returns horizontal direction of analog stick
pub fn stick_x(player: usize) f32 {
    return @intToFloat(f32, c.PAD_StickX(@intCast(i32, player))) / 128;
}

/// Returns vertical direction of analog stick
pub fn stick_y(player: usize) f32 {
    return @intToFloat(f32, c.PAD_StickY(@intCast(i32, player))) / 128;
}

/// Returns how far left trigger is held
pub fn trigger_l(player: usize) i8 {
    return c.PAD_TriggerL(player);
}

/// Returns how far right trigger is held
pub fn trigger_r(player: usize) i8 {
    return c.PAD_TriggerR(player);
}

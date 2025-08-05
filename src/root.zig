const std = @import("std");
const builtin = @import("builtin");

const backend = switch (builtin.os.tag) {
    .windows => @import("platform/win32/backend.zig"),
    .linux => @import("platform/wayland/backend.zig"),
    else => @compileError("Unsupported OS"),
};

pub const Error = error{
    NotInitialized,
    PlatformError,
    OutOfMemory,
};

const MAX_WINDOWS = 8;

const Context = struct {
    allocator: std.mem.Allocator,
    //TODO: windows: [MAX_WINDOWS]usize,
};

var initialized: bool = false;
var context: Context = undefined;

pub fn initialize(allocator: std.mem.Allocator) Error!void {
    try backend.initialize();

    context = Context{
        .allocator = allocator,
    };
    initialized = true;
}

pub fn deinit() void {
    backend.shutdown();
    initialized = false;
    context = undefined;
}

// pub const WindowHandle = *opaque {};
//
// pub const WindowConfig = struct {
//     title: []const u8,
//     pos_x: i32 = std.math.minInt(i32), // Use system provided pos_x
//     pos_y: i32 = std.math.minInt(i32), // Use system provided pos_x
//     width: u32,
//     height: u32,
// };
//
// pub fn initialize(allocator: std.mem.Allocator) bool {
//     return platform.initialize(allocator);
// }
//
// pub fn shutdown() void {
//     return platform.shutdown();
// }
//
// pub fn pump_messages() bool {
//     return platform.pump_messages();
// }
//
// pub fn createWindow(config: *const WindowConfig, show: bool) !WindowHandle {
//     return platform.createWindow(config, show);
// }
//
// pub fn windowShouldClose(handle: WindowHandle) bool {
//     return platform.windowShouldClose(handle);
// }

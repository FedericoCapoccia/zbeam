const std = @import("std");
const builtin = @import("builtin");

const Backend = @import("backend.zig").Backend;

pub const Error = error{
    NotInitialized,
    PlatformError,
    OutOfMemory,
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    backend: Backend,
};

pub fn createContext(allocator: std.mem.Allocator) Error!*Context {
    const backend = try Backend.initialize(allocator);
    const ctx = try allocator.create(Context);
    ctx.* = Context{
        .allocator = allocator,
        .backend = backend,
    };
    return ctx;
}

pub fn destroyContext(ctx: *Context) void {
    ctx.backend.shutdown(ctx.allocator);
    ctx.allocator.destroy(ctx);
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

const std = @import("std");
const builtin = @import("builtin");

const Error = @import("root.zig").Error;
const backend_win32 = @import("platform/win32/backend.zig");

pub const Backend = union(enum) {
    Windows: *backend_win32.Win32State,
    Wayland: void,

    pub fn initialize(allocator: std.mem.Allocator) Error!Backend {
        switch (builtin.os.tag) {
            .windows => return Backend{ .Windows = try backend_win32.initialize(allocator) },
            else => @compileError("Unsupported OS"),
        }
    }

    pub fn shutdown(self: *Backend) void {
        switch (self.*) {
            .Windows => |state| backend_win32.shutdown(state),
            .Wayland => {},
        }
    }
};

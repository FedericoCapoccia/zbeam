const std = @import("std");
const builtin = @import("builtin");

const platform = switch (builtin.os.tag) {
    .windows => @import("platform/win32/platform.zig"),
    .linux => @import("platform/wl/platform.zig"),
    else => @compileError("Unsupported OS"),
};

pub fn initialize() bool {
    return platform.initialize();
}

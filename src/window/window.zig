const std = @import("std");
const builtin = @import("builtin");

const backend = switch (builtin.os.tag) {
    .windows => @import("win32/backend.zig"),
    .linux => @import("linux/backend.zig"),
};

pub fn initialize() void {}

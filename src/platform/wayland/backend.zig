const std = @import("std");

const Error = @import("../../root.zig").Error;

pub fn initialize() Error!void {
    std.log.info("Initializing Wayland backend", .{});
}

pub fn shutdown() void {}

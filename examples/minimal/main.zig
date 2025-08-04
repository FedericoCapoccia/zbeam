const std = @import("std");

const zbm = @import("zbeam");

pub const UNICODE = true;

pub fn main() !void {
    if (!zbm.initialize()) {
        std.log.err("Failed to initialize zBeam", .{});
    }
    defer zbm.shutdown();
}

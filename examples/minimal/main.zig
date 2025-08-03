const std = @import("std");
const zbm = @import("zbeam");

pub fn main() !void {
    if (!zbm.initialize()) {
        std.log.err("Failed to initialize zBeam", .{});
    }
    defer zbm.shutdown();
}

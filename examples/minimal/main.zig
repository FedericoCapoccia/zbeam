const std = @import("std");
const zbm = @import("zbeam");

pub fn main() !void {
    std.log.info("Hello {d}", .{zbm.placeholder()});
}

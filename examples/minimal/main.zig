const std = @import("std");

const zbm = @import("zbeam");

pub const UNICODE = true;

pub fn main() !void {
    var dbga = std.heap.DebugAllocator(.{}).init;
    const allocator = dbga.allocator();
    defer {
        if (dbga.deinit() == .leak) {
            std.log.err("Leaked", .{});
        }
    }

    try zbm.initialize(allocator);
    defer zbm.deinit();

    // var window_config = zbm.WindowConfig{
    //     .title = "Minimal example",
    //     .width = 1280,
    //     .height = 720,
    // };
    //
    // const window = try zbm.createWindow(&window_config, true);
    //
    // while (!zbm.windowShouldClose(window)) {
    //     _ = zbm.pump_messages();
    // }
}

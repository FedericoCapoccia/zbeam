const std = @import("std");

const zbm = @import("zbeam");

pub const UNICODE = true;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Leaked", .{});
        }
    }

    const allocator = gpa.allocator();

    if (!zbm.initialize(allocator)) {
        std.log.err("Failed to initialize zBeam", .{});
    }
    defer zbm.shutdown();

    var window_config = zbm.WindowConfig{
        .title = "Minimal example",
        .width = 1280,
        .height = 720,
    };

    const window = try zbm.createWindow(&window_config, true);

    while (!zbm.windowShouldClose(window)) {
        _ = zbm.pump_messages();
    }
}

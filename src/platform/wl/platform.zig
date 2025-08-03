const std = @import("std");

const wayland = @import("wayland");
const wl = wayland.client.wl;

const WaylandPlatformState = struct {
    display: *wl.Display,
};

var state: WaylandPlatformState = undefined;

pub fn initialize() bool {
    state.display = wl.Display.connect(null) catch |err| {
        std.log.err("Failed to connect to wayland display: {s}", .{@errorName(err)});
        return false;
    };
    std.log.info("WlDisplay connected", .{});

    state.display.disconnect();
    return true;
}

const std = @import("std");

const wayland = @import("wayland");
const wl = wayland.client.wl;

const WaylandPlatformState = struct {
    display: *wl.Display,
    registry: *wl.Registry,
};

var g_state: ?WaylandPlatformState = null;

pub fn initialize() bool {
    const display = wl.Display.connect(null) catch |err| {
        std.log.err("Failed to connect to wayland display: {s}", .{@errorName(err)});
        return false;
    };
    std.log.info("WlDisplay connected", .{});

    const registry = display.getRegistry() catch |err| {
        std.log.err("Failed to retrieve registry: {s}", .{@errorName(err)});
        return false;
    };

    g_state = WaylandPlatformState{
        .display = display,
        .registry = registry,
    };
    return true;
}

pub fn shutdown() void {
    if (g_state) |state| {
        state.display.disconnect();
    }
}

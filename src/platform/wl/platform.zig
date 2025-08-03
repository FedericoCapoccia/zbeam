const std = @import("std");

const wayland = @import("wayland");
const wl = wayland.client.wl;

pub const WaylandPlatformState = struct {};

var state: WaylandPlatformState = {};

pub fn initialize() bool {
    return true;
}

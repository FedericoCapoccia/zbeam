const std = @import("std");

const win32_bindings = @import("win32");

const Error = @import("../../root.zig").Error;

const win32 = struct {
    const wm = @import("win32").ui.windows_and_messaging;
    const dwm = @import("win32").graphics.dwm;
    const gdi = @import("win32").graphics.gdi;
    const IMAGE_DOS_HEADER = @import("win32").system.system_services.IMAGE_DOS_HEADER;
    const HINSTANCE = @import("win32").foundation.HINSTANCE;
    const HWND = @import("win32").foundation.HWND;
};

extern const __ImageBase: win32.IMAGE_DOS_HEADER; // https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483

pub const Win32State = struct {
    allocator: std.mem.Allocator,
    hinstance: win32.HINSTANCE,
    window_class: u16,
};

/// Initializes Win32 backend state
pub fn initialize(allocator: std.mem.Allocator) Error!*Win32State {
    std.log.info("Initializing Win32 backend", .{});
    const hinstance: win32.HINSTANCE = @ptrCast(@constCast(&__ImageBase));

    const state = try allocator.create(Win32State);
    state.* = Win32State{
        .allocator = allocator,
        .hinstance = hinstance,
        .window_class = 0,
    };

    return state;
}

pub fn shutdown(state: *Win32State) void {
    state.allocator.destroy(state);
}

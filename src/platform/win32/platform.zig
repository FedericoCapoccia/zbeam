const std = @import("std");
const win32 = @import("win32");

pub const Win32PlatformState = struct {
    hinstance: std.os.windows.HINSTANCE,
};

pub fn initialize() bool {
    return true;
}

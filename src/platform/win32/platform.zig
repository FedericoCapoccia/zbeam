const std = @import("std");

// TODO:
// [ ] Fix error handling

const win32_bindings = @import("win32");

const win32 = struct {
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").graphics.dwm;
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
};

const WindowConfig = @import("../../root.zig").WindowConfig;
const WindowHandle = @import("../../root.zig").WindowHandle;

extern const __ImageBase: win32.IMAGE_DOS_HEADER;

pub const Win32PlatformState = struct {
    alloc: std.mem.Allocator,
    hinstance: win32.HINSTANCE,
    wcr: u16,
};

pub const NativeWin32Window = struct {
    hwnd: win32.HWND,
    title: []const u8,
    width: u32,
    height: u32,
    closed: bool = false,
};

var g_state: ?Win32PlatformState = null;
var main_window: ?NativeWin32Window = null;

pub fn initialize(allocator: std.mem.Allocator) bool {
    if (g_state) |_| {
        // NOTE: already been initialized
        // TODO: error system
        return false;
    }

    const hinstance: win32.HINSTANCE = @ptrCast(@constCast(&__ImageBase));

    const wc = win32.WNDCLASSEXW{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = .{
            .DBLCLKS = 1,
        },
        .lpfnWndProc = WindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hinstance,
        .hIcon = null,
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .hbrBackground = win32.GetSysColorBrush(@intFromEnum(win32.SYS_COLOR_INDEX.WINDOW)),
        .lpszMenuName = null,
        .lpszClassName = win32.L("zbeam_window_class"),
        .hIconSm = null,
    };

    const wcr = win32.RegisterClassExW(&wc);

    g_state = Win32PlatformState{
        .alloc = allocator,
        .hinstance = hinstance,
        .wcr = wcr,
    };
    return true;
}

pub fn pump_messages() bool {
    if (g_state) |_| {
        var message: win32.MSG = undefined;
        while (win32.PeekMessageW(&message, null, 0, 0, .{ .REMOVE = 1 }) > 0) {
            _ = win32.TranslateMessage(&message);
            _ = win32.DispatchMessageW(&message);
        }
    }
    return true;
}

pub fn createWindow(config: *const WindowConfig, show: bool) !WindowHandle {
    if (g_state == null) {
        return error.BeamNotInitialized;
    }

    if (main_window) |_| {
        return error.BeamSupportsOnlyOneWindowAtTheMomentToBeFixedTm;
    }

    const client_x = config.pos_x;
    const client_y = config.pos_y;
    const client_width = config.width;
    const client_height = config.height;

    var window_x = client_x;
    var window_y = client_y;
    var window_width = client_width;
    var window_height = client_height;

    const window_ex_style = win32.WINDOW_EX_STYLE{ .APPWINDOW = 1 };
    const window_style = win32.WS_OVERLAPPEDWINDOW;

    var border_rect = win32.RECT{ .bottom = 0, .left = 0, .right = 0, .top = 0 };
    _ = win32.AdjustWindowRectEx(&border_rect, window_style, 0, window_ex_style);

    if (client_x == std.math.minInt(i32)) {
        window_x = win32.CW_USEDEFAULT;
    } else {
        window_x += border_rect.left;
    }

    if (client_y == std.math.minInt(i32)) {
        window_y = win32.CW_USEDEFAULT;
    } else {
        window_y += border_rect.top;
    }

    window_width += @intCast(border_rect.right - border_rect.left);
    window_height += @intCast(border_rect.bottom - border_rect.top);

    const window_title = std.unicode.utf8ToUtf16LeAllocZ(g_state.?.alloc, config.title) catch win32.L("zBeam"); // wide_title
    defer g_state.?.alloc.free(window_title);

    const hwnd = win32.CreateWindowExW(
        window_ex_style,
        win32.L("zbeam_window_class"),
        window_title,
        window_style,
        window_x,
        window_y,
        @intCast(window_width),
        @intCast(window_height),
        null,
        null,
        g_state.?.hinstance,
        null,
    );

    if (hwnd == null) {
        return error.BeamWindowNotCreated;
    }

    var dark_mode: i32 = 1;
    _ = win32.DwmSetWindowAttribute(hwnd, .USE_IMMERSIVE_DARK_MODE, &dark_mode, @sizeOf(i32));

    if (show) {
        _ = win32.ShowWindow(hwnd, win32.SHOW_WINDOW_CMD{ .SHOWNORMAL = 1 });
    }

    main_window = NativeWin32Window{
        .hwnd = hwnd.?,
        .title = config.title,
        .width = client_width,
        .height = client_height,
    };

    return @ptrCast(main_window.?.hwnd);
}

pub fn shutdown() void {}

pub fn windowShouldClose(handle: WindowHandle) bool {
    _ = handle;
    if (main_window) |window| {
        return window.closed;
    }
    return true;
}

fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.winapi) win32.LRESULT {
    switch (uMsg) {
        win32.WM_ERASEBKGND => {
            return 1;
        },
        win32.WM_CLOSE => {
            if (main_window) |*wnd| {
                wnd.closed = true;
            }
            return 0;
        },
        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0;
        },
        win32.WM_DPICHANGED => {
            // TODO:
            return 0;
        },
        win32.WM_SIZE => {
            // TODO:
            return 0;
        },
        win32.WM_SHOWWINDOW => {
            if (win32.GetLayeredWindowAttributes(hwnd, null, null, null) == 0) {
                _ = win32.SetLayeredWindowAttributes(hwnd, 0, 0, .{ .ALPHA = 1 });
                _ = win32.DefWindowProc(hwnd, win32.WM_ERASEBKGND, @as(win32.WPARAM, @intFromPtr(win32.GetDC(hwnd))), lParam);
                _ = win32.SetLayeredWindowAttributes(hwnd, 0, 255, .{ .ALPHA = 1 });
                _ = win32.AnimateWindow(hwnd, 200, .{ .ACTIVATE = 1, .BLEND = 1 });
                return 0;
            }
        },
        else => {},
    }
    return win32.DefWindowProc(hwnd, uMsg, wParam, lParam);
}

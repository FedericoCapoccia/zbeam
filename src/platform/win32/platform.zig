const std = @import("std");

const win32_bindings = @import("win32");

const win32 = struct {
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
};

extern const __ImageBase: win32.IMAGE_DOS_HEADER;

pub const Win32PlatformState = struct {
    hinstance: win32.HINSTANCE,
    wcr: u16,
};

var g_state: ?Win32PlatformState = null;

pub fn initialize() bool {
    const hinstance: win32.HINSTANCE = @ptrCast(@constCast(&__ImageBase));

    const wc = win32.WNDCLASSEXW{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = .{
            .DBLCLKS = 1,
        },
        .lpfnWndProc = win32.DefWindowProcW,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hinstance,
        .hIcon = null,
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .hbrBackground = win32.GetStockObject(win32.BLACK_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = win32.L("zbeam_window_class"),
        .hIconSm = null,
    };

    const wcr = win32.RegisterClassExW(&wc);

    // TODO: move to createWindow
    const hwnd = win32.CreateWindowExW(
        win32.WINDOW_EX_STYLE{},
        win32.L("zbeam_window_class"),
        win32.L("zBeam window"),
        win32.WS_OVERLAPPEDWINDOW,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        1280,
        720,
        null,
        null,
        hinstance,
        null,
    );

    _ = win32.ShowWindow(hwnd, win32.SHOW_WINDOW_CMD{ .SHOWNORMAL = 1 });

    var msg: win32.MSG = undefined;
    while (win32.GetMessage(&msg, null, 0, 0) != 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessage(&msg);
    }

    g_state = Win32PlatformState{
        .hinstance = hinstance,
        .wcr = wcr,
    };
    return true;
}

pub fn shutdown() void {}

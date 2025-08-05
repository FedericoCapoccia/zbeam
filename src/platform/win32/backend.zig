const std = @import("std");

const Error = @import("../../root.zig").Error;

const win32 = struct {
    const bindings = @import("win32");
    const wm = @import("win32").ui.windows_and_messaging;
    const dwm = @import("win32").graphics.dwm;
    const gdi = @import("win32").graphics.gdi;

    const IMAGE_DOS_HEADER = @import("win32").system.system_services.IMAGE_DOS_HEADER;

    const HINSTANCE = @import("win32").foundation.HINSTANCE;
    const HWND = @import("win32").foundation.HWND;
    const WPARAM = @import("win32").foundation.WPARAM;
    const LPARAM = @import("win32").foundation.LPARAM;
    const LRESULT = @import("win32").foundation.LRESULT;

    const L = @import("win32").zig.L;
};

extern const __ImageBase: win32.IMAGE_DOS_HEADER; // https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483

const InternalState = struct {
    hinstance: win32.HINSTANCE,
};

var initialized: bool = false;
var internal_state: InternalState = undefined;

/// Initializes Win32 backend state
pub fn initialize() Error!void {
    std.log.info("Initializing Win32 backend", .{});
    const hinstance: win32.HINSTANCE = @ptrCast(@constCast(&__ImageBase));

    const wc = win32.wm.WNDCLASSEXW{
        .cbSize = @sizeOf(win32.wm.WNDCLASSEXW),
        .style = .{
            .DBLCLKS = 1,
        },
        .lpfnWndProc = WindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hinstance,
        .hIcon = null,
        .hCursor = win32.wm.LoadCursorW(null, win32.wm.IDC_ARROW),
        .hbrBackground = win32.gdi.GetSysColorBrush(@intFromEnum(win32.wm.SYS_COLOR_INDEX.WINDOW)),
        .lpszMenuName = null,
        .lpszClassName = win32.L("zbeam_window_class"),
        .hIconSm = null,
    };

    // FIXME: if using a dll it should be registered and unregistered in PROCESS_ATTACH and PROCESS_DETACH of Dllmain
    // or use GetClassInfoEx to test if the class has been already registered
    // https://stackoverflow.com/questions/150803/side-effects-of-calling-registerwindow-multiple-times-with-same-window-class
    if (win32.wm.RegisterClassExW(&wc) == 0) {
        // NOTE : Failed window class registration
        return Error.PlatformError;
    }

    internal_state = InternalState{
        .hinstance = hinstance,
    };
    initialized = true;
}

pub fn shutdown() void {
    if (!initialized) return;
    _ = win32.wm.UnregisterClassW(win32.L("zbeam_window_class"), internal_state.hinstance); // TODO: check if registered first
    initialized = false;
    internal_state = undefined;
}

// =======================
// Windows event handling
// =======================
fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.winapi) win32.LRESULT {
    switch (uMsg) {
        win32.wm.WM_ERASEBKGND => {
            return 1;
        },
        win32.wm.WM_CLOSE => {
            // TODO : pass Win32State as a window pointer to be retrieved and worked on
            // if (main_window) |*wnd| {
            //     wnd.closed = true;
            // }
            return 0;
        },
        win32.wm.WM_DESTROY => {
            win32.wm.PostQuitMessage(0);
            return 0;
        },
        win32.wm.WM_DPICHANGED => {
            // TODO:
            return 0;
        },
        win32.wm.WM_SIZE => {
            // TODO:
            return 0;
        },
        else => {},
    }
    return win32.wm.DefWindowProc(hwnd, uMsg, wParam, lParam);
}

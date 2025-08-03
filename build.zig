const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode for library") orelse .static;
    const build_examples = b.option(bool, "examples", "Build zBeam examples") orelse true;

    const zbeam_module = b.addModule("root", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib = b.addLibrary(.{
        .name = "zBeam",
        .linkage = linkage,
        .root_module = zbeam_module,
    });

    const check_step = b.step("check", "Type-check everything without emitting binaries");
    check_step.dependOn(&lib.step);

    // Add TranslateC of Win32API
    if (target.result.os.tag == .windows) {
        const win32_source =
            \\#define WIN32_LEAN_AND_MEAN
            \\#include <Windows.h>
            \\#include <dwmapi.h>
        ;

        const tc = b.addTranslateC(.{
            .root_source_file = b.addWriteFiles().add("win32.h", win32_source),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        const win32_mod = tc.addModule("win32");
        win32_mod.linkSystemLibrary("dwmapi", .{});
        lib.root_module.addImport("win32", win32_mod);
    }

    // Add TranslateC for Wayland
    if (target.result.os.tag == .linux) {
        const Scanner = @import("wayland").Scanner;
        const scanner = Scanner.create(b, .{});
        const wayland = b.createModule(.{ .root_source_file = scanner.result });

        // scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
        // scanner.addSystemProtocol("staging/ext-session-lock/ext-session-lock-v1.xml");

        // Pass the maximum version implemented by your wayland server or client.
        // Requests, events, enums, etc. from newer versions will not be generated,
        // ensuring forwards compatibility with newer protocol xml.
        // This will also generate code for interfaces created using the provided
        // global interface, in this example wl_keyboard, wl_pointer, xdg_surface,
        // xdg_toplevel, etc. would be generated as well.
        // scanner.generate("wl_seat", 4);
        // scanner.generate("xdg_wm_base", 3);
        // scanner.generate("ext_session_lock_manager_v1", 1);
        // scanner.generate("private_foobar_manager", 1);

        lib.root_module.addImport("wayland", wayland);
        lib.linkSystemLibrary("wayland-client");
    }

    b.installArtifact(lib);

    if (build_examples) {
        const cwd = std.fs.cwd();
        var examples_dir = cwd.openDir("examples", .{ .iterate = true }) catch |err| {
            std.log.warn("Could not open directory 'examples': {s}. Skipping example builds.", .{@errorName(err)});
            return;
        };
        defer examples_dir.close();

        var iterator = examples_dir.iterate();
        while (iterator.next() catch null) |entry| {
            if (entry.kind != .directory) continue;

            const name = entry.name;
            const path = b.pathJoin(&[_][]const u8{ "examples", name, "main.zig" });

            const main_file = cwd.openFile(path, .{}) catch |err| {
                std.log.warn("Skipping example '{s}' because 'main.zig' could not be opened: {s}.", .{ name, @errorName(err) });
                continue;
            };
            defer main_file.close();

            const exe = b.addExecutable(.{
                .name = name,
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
                .link_libc = zbeam_module.link_libc,
            });

            exe.root_module.addImport("zbeam", lib.root_module);
            exe.linkLibrary(lib);

            b.installArtifact(exe);

            check_step.dependOn(&exe.step);

            const run_exe = b.addRunArtifact(exe);
            run_exe.step.dependOn(b.getInstallStep());

            if (b.args) |args| {
                run_exe.addArgs(args);
            }

            const run_step_name = try std.fmt.allocPrint(b.allocator, "run-{s}", .{name});
            const run_step_desc = try std.fmt.allocPrint(b.allocator, "Run example '{s}'", .{name});
            const run_step = b.step(run_step_name, run_step_desc);
            run_step.dependOn(&run_exe.step);
        }
    }
}

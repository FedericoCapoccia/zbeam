const std = @import("std");

pub fn build(b: *std.Build) void {
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

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());

            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step_name = std.fmt.allocPrint(b.allocator, "run-{s}", .{name}) catch continue;
            const run_step_desc = std.fmt.allocPrint(b.allocator, "Run example '{s}'", .{name}) catch continue;
            const run_step = b.step(run_step_name, run_step_desc);
            run_step.dependOn(&run_cmd.step);
        }
    }
}

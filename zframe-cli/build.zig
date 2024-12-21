const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zframe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod_opt = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const zerver = b.dependency("zerver", .{
        .target = target,
        .optimize = mod_opt,
    });
    exe.root_module.addImport("zerver", zerver.module("zerver"));

    // const _md2html = b.dependency("md2html", .{
    //     .target = target,
    //     .optimize = .ReleaseFast,
    // });
    // exe.root_module.addImport("md2html", _md2html.module("md2html"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

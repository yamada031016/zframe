const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zframe",
        .root_source_file = b.path("src/zframe.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zframe_mod = b.addModule("zframe", .{
        .root_source_file = b.path("src/zframe.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    lib.root_module.addImport("zframe", zframe_mod);

    const md = b.dependency("markdown-zig", .{
        .target = target,
        .optimize = .ReleaseFast,
    });
    lib.root_module.addImport("markdown-zig", md.module("markdown-zig"));
    zframe_mod.addImport("markdown-zig", md.module("markdown-zig"));

    // const wasm_analyzer_optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    // const wasm_analyzer = b.dependency("wasm-binary-analyzer", .{
    //     .target = target,
    //     .optimize = wasm_analyzer_optimize,
    // });
    // lib.root_module.addImport("wasm-binary-analyzer", wasm_analyzer.module("wasm-binary-analyzer"));
    // zframe_mod.addImport("wasm-binary-analyzer", wasm_analyzer.module("wasm-binary-analyzer"));

    // const run_cmd = b.addRunArtifact(exe);

    // run_cmd.step.dependOn(b.getInstallStep());

    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    b.installArtifact(lib);

    const docs_step = b.step("docs", "Emit docs");
    const docs_install = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&docs_install.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/zframe.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

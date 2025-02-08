const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "zframe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
    });

    const zframe = b.createModule(.{ .root_source_file = b.path("../../src/zframe.zig") });
    exe.root_module.addImport("zframe", zframe);

    const components = b.createModule(.{ .root_source_file = b.path("src/components/components.zig") });
    components.addImport("zframe", zframe);
    components.addImport("components", components);
    exe.root_module.addImport("components", components);

    const api = b.createModule(.{ .root_source_file = b.path("src/api/api.zig") });
    api.addImport("zframe", zframe);
    api.addImport("api", api);
    exe.root_module.addImport("api", api);

    const cwd = std.fs.cwd();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    // TODO: only delete targets which have changes.
    // when generating html file, also generate unique hash value (from zig file metadata ?).
    // only in case of hash values are changed, delete old html files.
    cwd.makeDir("zig-out") catch {};
    cwd.makeDir("zig-out/html") catch {
        var output_dir = try cwd.openDir("zig-out/html", .{ .iterate = true });
        defer output_dir.close();
        var walker = try output_dir.walk(allocator);
        while (try walker.next()) |entry| {
            switch (entry.kind) {
                .directory => {
                    output_dir.deleteTree(entry.path) catch |e| {
                        try stdout.print("{s}: at {s}\n", .{ @errorName(e), entry.path });
                    };
                },
                .file => {
                    output_dir.deleteFile(entry.path) catch |e| {
                        try stdout.print("{s}: at {s}\n", .{ @errorName(e), entry.path });
                    };
                },
                else => {},
            }
        }
    };
    cwd.makeDir("zig-out/html/webcomponents") catch {};
    var html_dir = try cwd.openDir("zig-out/html", .{ .iterate = true });
    defer html_dir.close();

    try wasm_autobuild(b, allocator, html_dir);

    const js_dir = try html_dir.makeOpenPath("js", .{});
    move_contents(allocator, "src/js", js_dir) catch |err| {
        switch (err) {
            error.FileNotFound => std.log.err("src/js not found.\n", .{}),
            else => std.log.err("{s}\n", .{@errorName(err)}),
        }
    };
    move_contents(allocator, "public", html_dir) catch |err| {
        switch (err) {
            error.FileNotFound => std.log.err("public not found.\n", .{}),
            else => std.log.err("{s}\n", .{@errorName(err)}),
        }
    };

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn wasm_autobuild(b: *std.Build, allocator: std.mem.Allocator, root_dir: std.fs.Dir) !void {
    const whiteList = @import("src/api/api.zig").whiteList;
    // const whiteListString = try std.mem.concat(allocator, u8, &whiteList);
    // const wasm_dir = try std.fs.cwd().openDir("src/api/", .{ .iterate = true });
    // var wasm_walker = try wasm_dir.walk(allocator);
    root_dir.makeDir("api") catch {};
    for (whiteList) |wasm| {
        const wasm_api = b.addExecutable(.{
            .name = std.fs.path.stem(wasm),
            .root_source_file = b.path(try std.fmt.allocPrintZ(allocator, "src/api/{s}", .{wasm})),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .wasm32,
                .os_tag = .freestanding,
            }),
            .optimize = .ReleaseSmall,
        });
        wasm_api.rdynamic = true;
        wasm_api.stack_size = std.wasm.page_size;
        wasm_api.entry = .disabled;
        // wasm_api.initial_memory = std.wasm.page_size * 2;
        // wasm_api.max_memory = std.wasm.page_size * 2;

        const file_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.wasm", .{std.fs.path.stem(wasm)});
        // const wasm_install =b.addInstallArtifact(wasm_api, .{ .dest_dir = .default, .dest_sub_path=file_name});
        // b.getInstallStep().dependOn(&wasm_install.step);
        b.getInstallStep().dependOn(&b.addInstallArtifact(wasm_api, .{ .dest_dir = .{ .override = .{ .custom = "html/api" } }, .dest_sub_path = file_name }).step);
        // b.installBinFile(try std.fmt.allocPrint(std.heap.page_allocator, "zig-out/bin/{s}", .{file_name}), try std.fmt.allocPrint(std.heap.page_allocator, "../html/api/{s}", .{file_name}));
    }
    // while (try wasm_walker.next()) |file| {
    //     switch (file.kind) {
    //         .file => {
    //             // if (std.mem.containsAtLeast(u8, whiteListString, 1, file.path)) {
    //             const wasm_api = b.addExecutable(.{
    //                 .name = std.fs.path.stem(file.path),
    //                 .root_source_file = b.path(try std.fmt.allocPrintZ(allocator, "src/api/{s}", .{file.path})),
    //                 .target = b.resolveTargetQuery(.{
    //                     .cpu_arch = .wasm32,
    //                     .os_tag = .freestanding,
    //                 }),
    //                 .optimize = .ReleaseSmall,
    //             });
    //             wasm_api.rdynamic = true;
    //             wasm_api.stack_size = std.wasm.page_size;
    //             wasm_api.entry = .disabled;
    //             // wasm_api.initial_memory = std.wasm.page_size * 2;
    //             // wasm_api.max_memory = std.wasm.page_size * 2;
    //
    //             const file_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.wasm", .{std.fs.path.stem(file.path)});
    //             // const wasm_install =b.addInstallArtifact(wasm_api, .{ .dest_dir = .default, .dest_sub_path=file_name});
    //             // b.getInstallStep().dependOn(&wasm_install.step);
    //             b.getInstallStep().dependOn(&b.addInstallArtifact(wasm_api, .{ .dest_dir = .{ .override = .{ .custom = "html/api" } }, .dest_sub_path = file_name }).step);
    //             // b.installBinFile(try std.fmt.allocPrint(std.heap.page_allocator, "zig-out/bin/{s}", .{file_name}), try std.fmt.allocPrint(std.heap.page_allocator, "../html/api/{s}", .{file_name}));
    //             // }
    //         },
    //         else => {},
    //     }
    // }
}

fn move_contents(allocator: std.mem.Allocator, dir_name: []const u8, output_dir: std.fs.Dir) !void {
    const dir = try std.fs.cwd().openDir(dir_name, .{ .iterate = true });
    var walker = try dir.walk(allocator);
    while (try walker.next()) |file| {
        switch (file.kind) {
            .file => {
                try std.fs.Dir.copyFile(dir, file.path, output_dir, file.path, .{});
            },
            .directory => {
                const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir_name, file.path });
                try move_contents(allocator, path, try output_dir.makeOpenPath(file.path, .{}));
            },
            else => {},
        }
    }
}

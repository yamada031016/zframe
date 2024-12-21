const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "zframe-demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zframe = b.dependency("zframe", .{
        .target = target,
        .optimize = .ReleaseFast,
    });
    exe.root_module.addImport("zframe", zframe.module("zframe"));

    const components = b.createModule(.{ .root_source_file = b.path("src/components/components.zig") });
    components.addImport("zframe", zframe.module("zframe"));
    components.addImport("components", components);
    exe.root_module.addImport("components", components);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const cwd = std.fs.cwd();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    // TODO: only delete targets which have changes.
    // when generating html file, also generate unique hash value (from zig file metadata ?).
    // only in case of hash values are changed, delete old html files.
    cwd.makeDir("zig-out") catch {};
    cwd.makeDir("zig-out/webcomponents") catch {};
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
    try html_dir.chmod(0o777);
    defer html_dir.close();

    try wasm_autobuild(b, allocator, html_dir);
    try generate_pages(b, run_step, target, allocator, .{ .{ "zframe", zframe.module("zframe") }, .{ "components", components } });

    const js_dir = try html_dir.makeOpenPath("js", .{});
    try move_contents(allocator, "src/js", js_dir);
    try move_contents(allocator, "public", html_dir);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn generate_pages(b: *std.Build, run_step: *std.Build.Step, target: std.Build.ResolvedTarget, allocator: std.mem.Allocator, imports: anytype) !void {
    const cwd = std.fs.cwd();
    var md_output_dir = try cwd.openDir("zig-out/html", .{ .iterate = true });
    defer md_output_dir.close();
    const dir = try cwd.openDir("src/pages/", .{ .iterate = true });
    var walker = try dir.walk(allocator);
    while (try walker.next()) |file| {
        switch (file.kind) {
            .file => {
                if (std.mem.eql(u8, ".zig", std.fs.path.extension(file.path))) {
                    const page_exe = b.addExecutable(.{
                        .name = std.fs.path.stem(file.path),
                        .root_source_file = b.path(try std.fmt.allocPrintZ(allocator, "src/pages/{s}", .{file.path})),
                        .target = target,
                        .optimize = .ReleaseSmall,
                    });

                    inline for (imports) |import| {
                        page_exe.root_module.addImport(import[0], import[1]);
                    }

                    const page_run_cmd = b.addRunArtifact(page_exe);
                    page_run_cmd.step.dependOn(b.getInstallStep());
                    run_step.dependOn(&page_run_cmd.step);
                } else if (std.mem.eql(u8, ".md", std.fs.path.extension(file.path))) {
                    // var buf:[1024*10]u8 = undefined;
                    // const md = try file.dir.openFile(file.path, .{});
                    // const md_len = try md.readAll(&buf);
                    // var layoutPath:?[]const u8 = null;
                    // var title:?[]const u8 = null;
                    // const output = try md_output_dir.createFile(try std.fmt.allocPrint(std.heap.page_allocator, "{s}.html", .{std.fs.path.stem(file.path)}), .{});
                    // for(buf, 0..) |c, i| {
                    //     if(c == '@') {
                    //         if(std.mem.startsWith(u8, buf[i..], "@layout:")) {
                    //             layoutPath = findPath:{
                    //                 var path_buf:[64]u8 = undefined;
                    //                 var path_pos:usize = 0;
                    //                 for(buf[i+"layout:".len+1..]) |char|{
                    //                     if(char == ' ' or char == '\t') {
                    //                         continue;
                    //                     }
                    //                     if(char == '\n') {
                    //                         break :findPath path_buf[0..path_pos];
                    //                     }
                    //                     path_buf[path_pos] = char;
                    //                     path_pos += 1;
                    //                 }
                    //                 unreachable;
                    //             };
                    //         } else if (std.mem.startsWith(u8, buf[i..], "@title:")){
                    //             title = findTitle:{
                    //                 var title_buf:[64]u8 = undefined;
                    //                 var pos:usize = 0;
                    //                 for(buf[i+"title:".len+1..]) |char|{
                    //                     if(char == ' ' or char == '\t') {
                    //                         continue;
                    //                     }
                    //                     if(char == '\n') {
                    //                         break :findTitle title_buf[0..pos];
                    //                     }
                    //                     title_buf[pos] = char;
                    //                     pos += 1;
                    //                 }
                    //                 unreachable;
                    //             };
                    //         }
                    //     }
                    // }
                    // if (layoutPath) |path| {
                    //     const filePath = try std.fmt.allocPrint(std.heap.page_allocator, "src/components/{s}", .{std.fs.path.basename(path)});
                    //     cwd.access(".zig-cache/tmp/layout.html", .{}) catch {
                    //     };
                    // }
                    // const html = try @import("src/convert.zig").convert(buf[0..md_len]);
                    // try output.writeAll(html);
                    // defer output.close();
                }
            },
            else => {},
        }
    }
}

fn wasm_autobuild(b: *std.Build, allocator: std.mem.Allocator, root_dir: std.fs.Dir) !void {
    const wasm_dir = try std.fs.cwd().openDir("src/api/", .{ .iterate = true });
    var wasm_walker = try wasm_dir.walk(allocator);
    root_dir.makeDir("api") catch {};
    while (try wasm_walker.next()) |file| {
        switch (file.kind) {
            .file => {
                const wasm_api = b.addExecutable(.{
                    .name = std.fs.path.stem(file.path),
                    .root_source_file = b.path(try std.fmt.allocPrintZ(allocator, "src/api/{s}", .{file.path})),
                    .target = b.resolveTargetQuery(.{
                        .cpu_arch = .wasm32,
                        .os_tag = .freestanding,
                    }),
                    .optimize = .ReleaseSmall,
                });
                wasm_api.rdynamic = true;
                wasm_api.stack_size = std.wasm.page_size;
                wasm_api.entry = .disabled;
                // wasm_api.enable_wasmtime = true;
                // wasm_api.initial_memory = std.wasm.page_size * 2;
                // wasm_api.max_memory = std.wasm.page_size * 2;

                const file_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.wasm", .{std.fs.path.stem(file.path)});
                // const wasm_install =b.addInstallArtifact(wasm_api, .{ .dest_dir = .default, .dest_sub_path=file_name});
                // b.getInstallStep().dependOn(&wasm_install.step);
                b.getInstallStep().dependOn(&b.addInstallArtifact(wasm_api, .{ .dest_dir = .{ .override = .{ .custom = "html/api" } }, .dest_sub_path = file_name }).step);
                // b.installBinFile(try std.fmt.allocPrint(std.heap.page_allocator, "zig-out/bin/{s}", .{file_name}), try std.fmt.allocPrint(std.heap.page_allocator, "../html/api/{s}", .{file_name}));
            },
            else => {},
        }
    }
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

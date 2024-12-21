const std = @import("std");
const log = std.log;
const Browser = @import("browser.zig").Browser;
const FileMonitor = @import("file-monitor.zig").FileMonitor;
const HTTPServer = @import("zerver").HTTPServer;
const WebSocketManager = @import("zerver").WebSocketManager;
const WebSocketServer = @import("zerver").WebSocketServer;
// const md2html = @import("md2html");

fn usage_cmd() []const u8 {
    return (
        \\Usage: zframe [command] [option]
        \\
        \\Commands:
        \\
        \\  init        Initialize zin project at the current directory
        \\  build       Build zin project
        \\  update      Update all dependencies
        \\
        \\  help        Show this help messages.
        \\
        \\General Options:
        \\
        \\  -h, --help  Show this help messages.
    );
}

fn insertWebSocketConnectionCode(manager: WebSocketManager) !void {
    const dir = try std.fs.cwd().openDir("zig-out/html", .{ .iterate = true });
    var walker = try dir.walk(std.heap.page_allocator);
    while (try walker.next()) |file| {
        switch (file.kind) {
            .file => {
                if (std.mem.eql(u8, ".html", std.fs.path.extension(file.path))) {
                    var output = try std.fs.cwd().openFile(
                        try std.fmt.allocPrintZ(std.heap.page_allocator, "zig-out/html/{s}", .{file.path}),
                        .{ .mode = .read_write },
                    );
                    try output.pwriteAll(try std.fmt.allocPrint(
                        std.heap.page_allocator,
                        // "<script type='text/javascript'>var con=new WebSocket(\"ws://localhost:{d}\");con.onopen=function(e){{console.log(e);con.onmessage=function(e){{console.log(e);window.location.reload()}}}}</script>",
                        "<script> var con = new WebSocket('ws://localhost:{d}');con.onopen = function(event) {{console.log(event); con.onmessage = function(event) {{ window.location.reload(); }} }} </script> ",
                        .{manager.listener.listen_address.getPort()},
                    ), try output.getEndPos());
                }
            },
            else => {},
        }
    }
}

fn serve() !void {
    const observe_dir = "src";

    const ip_addr = "0.0.0.0";
    var server = try HTTPServer.init("zig-out/html", ip_addr, 3000);
    defer server.deinit();

    var manager = try WebSocketManager.init(5555);
    try insertWebSocketConnectionCode(manager);

    var browser = try Browser.init(.chrome, server.listener.listen_address.getPort());
    try browser.openHtml();
    var Monitor = try FileMonitor.init(observe_dir);
    defer Monitor.deinit();

    const thread = try std.Thread.spawn(.{}, HTTPServer.serve, .{server});
    _ = thread;
    _ = try std.Thread.spawn(.{}, WebSocketManager.waitConnection2, .{@constCast(&manager)});
    while (true) {
        if (Monitor.detectChanges()) {
            const status = try execute_command(.{ "zig", "build", "run" });
            if (status == 0) {
                try insertWebSocketConnectionCode(manager);
                try stdout.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
                try manager.reload();
            }
        }
    }
}
// fn mdToHTML() !void {
//     var md_dir = try std.fs.cwd().openDir("src/pages", .{ .iterate = true });
//     defer md_dir.close();
//     var md_output_dir = try std.fs.cwd().openDir("zig-out/html", .{ .iterate = true });
//     defer md_output_dir.close();
//     var walker = try md_dir.walk(std.heap.page_allocator);
//     while (try walker.next()) |file| {
//         switch (file.kind) {
//             .file => {
//                 if (std.mem.eql(u8, ".md", std.fs.path.extension(file.path))) {
//                     var buf: [1024 * 10]u8 = undefined;
//                     const md = try file.dir.openFile(file.path, .{});
//                     const md_len = try md.readAll(&buf);
//                     const html = try md2html.convert(buf[0..md_len]);
//                     const output = try md_output_dir.createFile(try std.fmt.allocPrint(std.heap.page_allocator, "{s}.html", .{std.fs.path.stem(file.path)}), .{});
//                     try output.writeAll(html);
//                     defer output.close();
//                 }
//             },
//             else => {},
//         }
//     }
// }

fn initProject(name: []const u8) !void {
    const cwd = std.fs.cwd();
    if (cwd.makeDir(name)) {
        const project_dir = try cwd.openDir(name, .{});
        {
            const dir_path = [_][]const u8{ "src", "src/pages", "src/components", "src/api", "src/js", "public", ".plugins" };
            for (dir_path) |path| {
                try project_dir.makeDir(path);
            }
        }
        const create_paths = [_][]const u8{ "src/main.zig", "src/pages/index.zig", "src/components/components.zig", "src/components/layout.zig", "src/components/head.zig", "build.zig" };

        const self_exe_path = try std.fs.selfExePathAlloc(std.heap.page_allocator);
        var cur_path: []const u8 = self_exe_path;
        const template_dir = while (std.fs.path.dirname(cur_path)) |dirname| : (cur_path = dirname) {
            var base_dir = cwd.openDir(dirname, .{}) catch continue;
            defer base_dir.close();

            const src_dir = existsSrc: {
                const src_zig = "src";
                const _src_dir = base_dir.openDir(src_zig, .{}) catch continue;
                break :existsSrc std.Build.Cache.Directory{ .path = src_zig, .handle = _src_dir };
            };
            break try src_dir.handle.openDir("init", .{});
        } else {
            unreachable;
        };

        const max_bytes = 10 * 1024 * 1024;
        for (create_paths) |path| {
            // try project_dir.makePath(path);
            const contents = try template_dir.readFileAlloc(std.heap.page_allocator, path, max_bytes);
            try project_dir.writeFile(.{ .sub_path = path, .data = contents, .flags = .{ .exclusive = true } });
        }

        const cmd = try std.fmt.allocPrint(std.heap.page_allocator, "cd {s} ; zig fetch --save=zframe https://github.com/yamada031016/zframe/archive/refs/heads/master.tar.gz", .{name});
        _ = try execute_command(.{ "sh", "-c", cmd });
    } else |_| {
        log.err("{s} is already exists.", .{name});
    }
}

fn update_dependencies() !void {
    const cmd = try std.fmt.allocPrint(std.heap.page_allocator, "zig fetch --save=zframe https://github.com/yamada031016/zframe/archive/refs/heads/master.tar.gz", .{});
    _ = try execute_command(.{ "sh", "-c", cmd });
    const cwd = std.fs.cwd();
    const self_exe_path = try std.fs.selfExePathAlloc(std.heap.page_allocator);
    var cur_path: []const u8 = self_exe_path;

    const template_dir = while (std.fs.path.dirname(cur_path)) |dirname| : (cur_path = dirname) {
        var base_dir = cwd.openDir(dirname, .{}) catch continue;
        defer base_dir.close();

        const src_dir = existsSrc: {
            const src_zig = "src";
            const _src_dir = base_dir.openDir(src_zig, .{}) catch continue;
            break :existsSrc std.Build.Cache.Directory{ .path = src_zig, .handle = _src_dir };
        };
        break try src_dir.handle.openDir("init", .{});
    } else {
        unreachable;
    };

    const max_bytes = 10 * 1024 * 1024;
    const contents = try template_dir.readFileAlloc(std.heap.page_allocator, "build.zig", max_bytes);
    atomic: {
        try std.fs.Dir.copyFile(cwd, "build.zig", try cwd.openDir(".zig-cache", .{}), "old_build.zig", .{});
        try cwd.deleteFile("build.zig");
        cwd.writeFile(.{ .sub_path = "build.zig", .data = contents, .flags = .{ .exclusive = true, .truncate = true } }) catch |e| {
            std.log.err("{s}\n", .{@errorName(e)});
            try std.fs.Dir.copyFile(try cwd.openDir(".zig-cache", .{}), "old_build.zig", cwd, "build.zig", .{});
            break :atomic;
        };
        break :atomic;
    }
}

const stdout = std.io.getStdOut().writer();

fn handleTty() !void {
    var tty = try std.fs.cwd().openFile("/dev/tty", .{ .mode = .read_write });
    defer tty.close();

    const original = try posix.tcgetattr(tty.handle);
    const raw = config: {
        var raw = original;
        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;
        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.iflag.BRKINT = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;
        raw.cc[@intFromEnum(os.linux.V.TIME)] = 0;
        raw.cc[@intFromEnum(os.linux.V.MIN)] = 1;
        break :config raw;
    };
    try posix.tcsetattr(tty.handle, .FLUSH, raw);
    try enterAlt();
    try stdout.writeAll("\x1B[2J"); // clear screen
    try stdout.writeAll("\x1B[0;0H"); // clear screen

    const reader = tty.reader();
    while (reader.readByte()) |byte| {
        if (byte == 'c' & '\x1F' or byte == 'q') {
            try posix.tcsetattr(tty.handle, .FLUSH, original);
            try stdout.writeAll("\x1B[2J"); // clear screen
            try leaveAlt();
            std.posix.exit(0);
        }
    } else |e| {
        log.err("{s}", .{@errorName(e)});
    }
}

fn enterAlt() !void {
    try stdout.writeAll("\x1B[s"); // Save cursor position.
    try stdout.writeAll("\x1B[?47h"); // Save screen.
    try stdout.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

fn leaveAlt() !void {
    try stdout.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    try stdout.writeAll("\x1B[?47l"); // Restore screen.
    try stdout.writeAll("\x1B[u"); // Restore cursor position.
}

const os = std.os;
const posix = std.posix;
pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const thread = try std.Thread.spawn(.{}, handleTty, .{});
    _ = thread;

    if (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "help")) {
            std.debug.print(usage_cmd(), .{});
        } else if (std.mem.eql(u8, arg, "init")) {
            if (args.next()) |project_name| {
                try initProject(project_name);
            } else {
                std.log.err("zframe init <project_name>", .{});
            }
        } else if (std.mem.eql(u8, arg, "build")) {
            const status = try execute_command(.{ "/bin/zig", "build", "run" });
            if (status == 0) {
                try stdout.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
            }
            // try mdToHTML();
            if (args.next()) |option| {
                if (std.mem.eql(u8, option, "serve")) {
                    try serve();
                } else if (std.mem.eql(u8, option, "-h")) {}
            }
        } else if (std.mem.eql(u8, arg, "update")) {
            try update_dependencies();
        } else {
            std.log.err("Invalid command: {s}", .{arg});
            std.debug.print(usage_cmd(), .{});
        }
    } else {
        log.err("expected command argument", .{});
        std.debug.print(usage_cmd(), .{});
    }
}

fn execute_command(command: anytype) !u32 {
    const fork_pid = try std.posix.fork();
    if (fork_pid == 0) {
        // child process
        const err = std.process.execve(std.heap.page_allocator, &command, null); // noreturn if success
        std.log.err("{s}", .{@errorName(err)});
    } else {
        // parent process
        const wait_result = std.posix.waitpid(fork_pid, 0);
        return wait_result.status;
    }
    unreachable;
}

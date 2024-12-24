const std = @import("std");
const log = std.log;
const Browser = @import("browser.zig").Browser;
const FileMonitor = @import("file-monitor.zig").FileMonitor;
const zerver = @import("zerver");
const HTTPServer = zerver.HTTPServer;
const WebSocketManager = zerver.WebSocketManager;
const WebSocketServer = zerver.WebSocketServer;
// const md2html = @import("md2html");
const tag = @import("builtin").os.tag;

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

fn serve(stdout:std.fs.File.Writer) !void {
    const observe_dir = "src";

    const exe_opt = zerver.ExecuteOptions{
        .dirname = "zig-out/html",
        .ip_addr = "0.0.0.0",
        .port_number = 3000,
    };
    var server = try HTTPServer.init(exe_opt);
    defer server.deinit();

    var manager = try WebSocketManager.init(5555);
    try insertWebSocketConnectionCode(manager);

    var browser = try Browser.init(.chrome, server.listener.listen_address.getPort());
    try browser.openHtml();
    var Monitor = try FileMonitor.init(observe_dir);
    defer Monitor.deinit();

    const thread = try std.Thread.spawn(.{}, HTTPServer.serve, .{server});
    _ = thread;
    _ = try std.Thread.spawn(.{}, WebSocketManager.connect, .{@constCast(&manager)});
    while (true) {
        if (try Monitor.detectChanges()) {
            const status = try execute_command("zig build run");
            if (status == 0) {
                try insertWebSocketConnectionCode(manager);
                try stdout.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
                try manager.sendData("Reload!");
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
        _ = try execute_command(cmd);
    } else |_| {
        log.err("{s} is already exists.", .{name});
    }
}

fn update_dependencies() !void {
    const cmd = try std.fmt.allocPrint(std.heap.page_allocator, "zig fetch --save=zframe https://github.com/yamada031016/zframe/archive/refs/heads/master.tar.gz", .{});
    _ = try execute_command(cmd);
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

fn handleTty(stdout:std.fs.File.Writer) !void {
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
    try enterAlt(stdout);
    try stdout.writeAll("\x1B[2J"); // clear screen
    try stdout.writeAll("\x1B[0;0H"); // clear screen

    const reader = tty.reader();
    while (reader.readByte()) |byte| {
        if (byte == 'c' & '\x1F' or byte == 'q') {
            try posix.tcsetattr(tty.handle, .FLUSH, original);
            try stdout.writeAll("\x1B[2J"); // clear screen
            try leaveAlt(stdout);
            std.posix.exit(0);
        }
    } else |e| {
        log.err("{s}", .{@errorName(e)});
    }
}

fn enterAlt(stdout:std.fs.File.Writer) !void {
    try stdout.writeAll("\x1B[s"); // Save cursor position.
    try stdout.writeAll("\x1B[?47h"); // Save screen.
    try stdout.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

fn leaveAlt(stdout:std.fs.File.Writer) !void {
    try stdout.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    try stdout.writeAll("\x1B[?47l"); // Restore screen.
    try stdout.writeAll("\x1B[u"); // Restore cursor position.
}

const os = std.os;
const posix = std.posix;
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    _ = args.skip();
    switch(tag) {
        .linux => {
            const thread = try std.Thread.spawn(.{}, handleTty, .{stdout});
            _ = thread;
        },
        else => {},
    }

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
            const status = try execute_command("zig build run");
            if (status == 0) {
                try stdout.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
            }
            // try mdToHTML();
            if (args.next()) |option| {
                if (std.mem.eql(u8, option, "serve")) {
                    try serve(stdout);
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

pub fn execute_command(command: []const u8) !u32 {
    switch(tag) {
        .linux,.macos => return posixExecCmd(.{"sh","-c",command}),
        .windows => {
            return windowsExecCmd(command);
        },
        else => @panic("unsupported OS"),
    }
}

fn posixExecCmd(command:anytype) !u32 {
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

const windows = std.os.windows;
fn windowsExecCmd(command: []const u8) !windows.DWORD {
    const cmd:[:0]const u16 = convert:{
        var buf:[256]u16 = undefined;
        var buf_pos:u8 = 0;
        for(command) |char| {
            buf[buf_pos] = @intCast(char);
            buf_pos += 1;
        }
        break :convert try std.heap.page_allocator.dupeZ(u16,buf[0..buf_pos]);
    };
    const child_proc = spawn: {
        var startup_info: windows.STARTUPINFOW = .{
            .cb = @sizeOf(windows.STARTUPINFOW),
            .lpReserved = null,
            .lpDesktop = null,
            .lpTitle = null,
            .dwX = 0,
            .dwY = 0,
            .dwXSize = 0,
            .dwYSize = 0,
            .dwXCountChars = 0,
            .dwYCountChars = 0,
            .dwFillAttribute = 0,
            .dwFlags = windows.STARTF_USESTDHANDLES,
            .wShowWindow = 0,
            .cbReserved2 = 0,
            .lpReserved2 = null,
            .hStdInput = null,
            .hStdOutput = null,
            .hStdError = windows.GetStdHandle(windows.STD_ERROR_HANDLE) catch null,
        };
        var proc_info: windows.PROCESS_INFORMATION = undefined;

        try windows.CreateProcessW(
            null,
            @constCast(cmd.ptr),
            null,
            null,
            windows.FALSE,
            0,
            null,
            null,
            &startup_info,
            &proc_info,
        );
        windows.CloseHandle(proc_info.hThread);

        break :spawn proc_info.hProcess;
    };
    defer windows.CloseHandle(child_proc);
    try windows.WaitForSingleObjectEx(child_proc, windows.INFINITE, false);

    var exit_code: windows.DWORD = undefined;
    if (windows.kernel32.GetExitCodeProcess(child_proc, &exit_code) == 0) {
        return error.UnableToGetExitCode;
    }
    return exit_code;
}

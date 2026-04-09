const std = @import("std");
const log = std.log;

const Browser = @import("browser.zig").Browser;
const FileMonitor = @import("file-monitor.zig").FileMonitor;

const zerver = @import("zerver");
const HTTPServer = zerver.HTTPServer;
const WebSocketManager = zerver.WebSocketManager;
const WebSocketServer = zerver.WebSocketServer;

const Allocator = std.mem.Allocator;
// const md2html = @import("md2html");

const tag = @import("builtin").os.tag;

const Command = union(CommandEnum) {
    const CommandEnum = enum { help, init, build, update };

    help,
    init: []const u8,
    build: bool, //serve flag,
    update,

    pub fn parse(allocator: Allocator, args: std.process.Args) !Command {
        var it = try args.iterateAllocator(allocator);
        _ = it.skip();

        const first = it.next() orelse return error.NoCommand;

        const command = std.meta.stringToEnum(CommandEnum, first) orelse {
            return error.InvalidCommand;
        };

        switch (command) {
            .help => return .help,
            .init => {
                const name = it.next() orelse return error.MissingArgument;
                return .{ .init = name };
            },
            .build => {
                const next = it.next();
                return .{ .build = next != null and std.mem.eql(u8, next.?, "serve") };
            },
            .update => return .update,
        }
    }
};

fn dispatch(io: std.Io, cmd: Command, allocator: Allocator, writer: *std.Io.Writer, cmd_path: []const u8) !void {
    switch (cmd) {
        .help => printUsage(),
        .init => |name| try initProject(io, allocator, name, cmd_path),
        .build => |serve_flag| try buildCommand(io, allocator, writer, serve_flag),
        .update => try updateDependencies(),
    }
}

fn printUsage() []const u8 {
    return (
        \\Usage: zframe [command] [option]
        \\
        \\Commands:
        \\
        \\  init        Initialize zframe project at the current directory
        \\  build       Build zframe project
        \\  update      Update all dependencies
        \\
        \\  help        Show this help messages.
        \\
        \\General Options:
        \\
        \\  -h, --help  Show this help messages.
    );
}

fn buildCommand(io: std.Io, allocator: Allocator, writer: *std.Io.Writer, serve_flag: bool) !void {
    // const status = try executeCommand("zig build run");
    const result = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{ "zig", " build ", "run" } });

    if (result.term == .exited) {
        try writer.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
        try writer.flush();
    }

    if (serve_flag) {
        try serve(io, allocator, writer);
    }
}

fn serve(io: std.Io, allocator: Allocator, writer: *std.Io.Writer) !void {
    const observe_dir = "src";

    var server = try HTTPServer.init(
        io,
        allocator,
        "zig-out/html",
        try std.Io.net.IpAddress.parse("0.0.0.0", 3000),
    );
    defer server.deinit();

    var manager = try WebSocketManager.init(5555);

    try injectLiveReload(manager);

    var browser = try Browser.init(.chrome, server.listener.socket.address.getPort());
    browser.openHtml() catch std.log.err("xdg-open is not installed\n", .{});

    _ = try std.Thread.spawn(.{}, HTTPServer.serve, .{server});
    _ = try std.Thread.spawn(.{}, WebSocketManager.connect, .{@constCast(&manager)});

    var Monitor = try FileMonitor.init(observe_dir);
    defer Monitor.deinit();

    while (true) {
        if (try Monitor.detectChanges()) {
            // const status = try executeCommand("zig build run");
            const result = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{ "zig", " build ", "run" } });

            // if (status == 0) {
            if (result.term == .exited) {
                try injectLiveReload(manager);
                try writer.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
                try writer.flush();
                try manager.sendData("Reload!");
            }
        }
    }
}

fn injectLiveReload(io: std.Io, manager: WebSocketManager) !void {
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out/html", .{ .iterate = true });
    var walker = try dir.walk(std.heap.page_allocator);

    while (try walker.next()) |file| {
        if (file.kind != .file) continue;
        if (!std.mem.eql(u8, ".html", std.fs.path.extension(file.path))) continue;

        const path = try std.fmt.allocPrint(std.heap.page_allocator, "zig-out/html/{s}", .{file.path});

        var output = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_write });

        const script = try std.fmt.allocPrint(
            std.heap.page_allocator,
            // "<script type='text/javascript'>var con=new WebSocket(\"ws://localhost:{d}\");con.onopen=function(e){{console.log(e);con.onmessage=function(e){{console.log(e);window.location.reload()}}}}</script>",
            "<script> var con = new WebSocket('ws://localhost:{d}');con.onopen = function(event) {{console.log(event); con.onmessage = function(event) {{ window.location.reload(); }} }} </script> ",
            .{manager.listener.socket.address.getPort()},
        );
        try output.pwriteAll(script, try output.getEndPos());
    }
}

fn createProjectDirs(io: std.Io, dir: std.Io.Dir) !void {
    const paths = [_][]const u8{
        "src",
        "src/pages",
        "src/components",
        "src/api",
        "src/js",
        "public",
        ".plugins",
    };

    for (paths) |path| {
        try dir.createDir(io, path, .default_dir);
    }
}

fn locateTemplateDir(io: std.Io, allocator: Allocator, cmd_path: []const u8) !std.Io.Dir {
    const cwd = std.Io.Dir.cwd();

    const exe_path = try std.fs.path.resolve(allocator, &[_][]const u8{cmd_path});
    defer allocator.free(exe_path);

    var cur: []const u8 = exe_path;

    while (std.fs.path.dirname(cur)) |dirname| : (cur = dirname) {
        var base = cwd.openDir(io, dirname, .{}) catch continue;
        defer base.close(io);

        var src_dir = existsSrc: {
            const src_zig = "src";
            const _src_dir = base.openDir(io, src_zig, .{}) catch continue;
            break :existsSrc std.Build.Cache.Directory{ .path = src_zig, .handle = _src_dir };
        };
        defer src_dir.closeAndFree(allocator, io);

        return try src_dir.handle.openDir(io, "init", .{});
    }

    return error.TemplateNotFound;
}

fn copyTemplateFiles(
    io: std.Io,
    allocator: Allocator,
    template_dir: std.Io.Dir,
    project_dir: std.Io.Dir,
) !void {
    const create_paths = [_][]const u8{
        "src/main.zig",
        "src/pages/index.zig",
        "src/components/components.zig",
        "src/components/layout.zig",
        "src/components/head.zig",
        "src/api/api.zig",
        "build.zig",
    };

    const max_bytes = 10 * 1024 * 1024;
    for (create_paths) |path| {
        // try project_dir.makePath(path);
        const contents = try template_dir.readFileAlloc(io, path, allocator, std.Io.Limit.limited(max_bytes));
        defer allocator.free(contents);

        try project_dir.writeFile(
            io,
            .{
                .sub_path = path,
                .data = contents,
                .flags = .{ .exclusive = true },
            },
        );
    }
}

fn installDependencies(io: std.Io, allocator: Allocator, name: []const u8) !void {
    const cmd = try std.fmt.allocPrint(
        allocator,
        "cd {s} ; zig fetch --save=zframe https://github.com/yamada031016/zframe/archive/refs/heads/master.tar.gz",
        .{name},
    );
    defer allocator.free(cmd);

    // _ = try executeCommand(cmd);
    _ = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{ "sh", "-c", cmd } });
}

fn initProject(io: std.Io, allocator: Allocator, name: []const u8, cmd_path: []const u8) !void {
    const cwd = std.Io.Dir.cwd();

    if (cwd.createDir(io, name, .default_dir)) {
        const project_dir = try cwd.openDir(io, name, .{});

        try createProjectDirs(io, project_dir);

        const template_dir = try locateTemplateDir(io, allocator, cmd_path);

        try copyTemplateFiles(io, allocator, template_dir, project_dir);

        try installDependencies(io, allocator, name);
    } else |_| {
        std.log.err("{s} is already exists.", .{name});
    }
}

test "createProjectDirs creates expected dirs" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try createProjectDirs(tmp.dir);
    const io = std.testing.io;

    try tmp.dir.openDir(io, "src", .{});
    try tmp.dir.openDir(io, "public", .{});
}

test "locateTemplateDir fails when not found" {
    const allocator = std.testing.allocator;

    const result = locateTemplateDir(std.testing.io, allocator);
    try std.testing.expectError(error.TemplateNotFound, result);
}
fn updateDependencies(allocator: Allocator) !void {
    try fetchDependencies(allocator);

    const template_dir = try locateTemplateDir(allocator);

    const contents = try loadTemplateFile(
        allocator,
        template_dir,
        "build.zig",
    );
    defer allocator.free(contents);

    try safeReplaceFile("build.zig", contents);
}

fn fetchDependencies(io: std.Io, allocator: Allocator) !void {
    const cmd = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "zig fetch --save=zframe https://github.com/yamada031016/zframe/archive/refs/heads/master.tar.gz",
        .{},
    );
    defer allocator.free(cmd);

    // _ = try executeCommand(cmd);
    _ = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{ "sh", "-c", cmd } });
}

fn loadTemplateFile(
    allocator: Allocator,
    dir: std.Io.Dir,
    path: []const u8,
) ![]u8 {
    const max_bytes = 10 * 1024 * 1024;
    return try dir.readFileAlloc(allocator, path, max_bytes);
}

fn safeReplaceFile(io: std.Io, filename: []const u8, new_data: []const u8) !void {
    const cwd = std.Io.Dir.cwd();

    const backup_dir = try cwd.openDir(io, ".zig-cache", .{});
    defer backup_dir.close(io);

    // 1. buckup
    try std.Io.Dir.copyFile(cwd, filename, backup_dir, "old_build.zig", .{});

    // 2. delete original
    try cwd.deleteFile(filename);

    // 3. write new
    cwd.writeFile(.{
        .sub_path = filename,
        .data = new_data,
        .flags = .{ .exclusive = true, .truncate = true },
    }) catch |err| {
        std.log.err("failed to update {s}: {s}\n", .{ filename, @errorName(err) });

        // roleback
        try std.Io.Dir.copyFile(backup_dir, "old_build.zig", cwd, filename, .{});

        return err;
    };
}

test "loadTemplateFile fails on missing file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try std.testing.expectError(
        error.FileNotFound,
        loadTemplateFile(std.testing.allocator, tmp.dir, "nope.zig"),
    );
}

test "safeReplaceFile writes file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const cwd = tmp.dir;

    try cwd.writeFile(.{ .sub_path = "build.zig", .data = "old" });

    try safeReplaceFile("build.zig", "new");

    const data = try cwd.readFileAlloc(std.testing.allocator, "build.zig", 100);
    defer std.testing.allocator.free(data);

    try std.testing.expect(std.mem.eql(u8, data, "new"));
}

const ESC = "\x1B";

const TtyController = struct {
    tty: std.Io.File,
    original: std.posix.termios,
    stdout: std.Io.File.Writer,

    pub fn init(io: std.Io, stdout: std.Io.File.Writer) !TtyController {
        const tty = try std.Io.Dir.cwd().openFile(io, "/dev/tty", .{ .mode = .read_write });
        const original = try std.posix.tcgetattr(tty.handle);

        var controller = TtyController{
            .tty = tty,
            .original = original,
            .stdout = stdout,
        };

        try controller.enableRawMode();
        try controller.enterAltScreen();
        try controller.clear();

        return controller;
    }

    pub fn deinit(self: *TtyController, io: std.Io) void {
        _ = std.posix.tcsetattr(self.tty.handle, .FLUSH, self.original) catch unreachable;
        self.leaveAltScreen() catch {};
        self.tty.close(io);
    }

    fn enableRawMode(self: *TtyController) !void {
        var raw = self.original;

        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;

        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.iflag.BRKINT = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;

        raw.cc[@intFromEnum(std.os.linux.V.TIME)] = 0;
        raw.cc[@intFromEnum(std.os.linux.V.MIN)] = 1;

        try std.posix.tcsetattr(self.tty.handle, .FLUSH, raw);
    }

    fn clear(self: *TtyController) !void {
        const writer = &self.stdout.interface;
        try writer.writeAll(ESC ++ "[2J");
        try writer.writeAll(ESC ++ "[0;0H");
    }

    fn enterAltScreen(self: *TtyController) !void {
        const writer = &self.stdout.interface;
        try writer.writeAll("\x1B[s"); // Save cursor position.
        try writer.writeAll("\x1B[?47h"); // Save screen.
        try writer.writeAll("\x1B[?1049h"); // Enable alternative buffer.
    }

    fn leaveAltScreen(self: *TtyController) !void {
        const writer = &self.stdout.interface;
        try writer.writeAll("\x1B[?1049l"); // Disable alternative buffer.
        try writer.writeAll("\x1B[?47l"); // Restore screen.
        try writer.writeAll("\x1B[u"); // Restore cursor position.
    }

    pub fn eventLoop(self: *TtyController, io: std.Io) !void {
        var reader_wrapper = self.tty.reader(io, &.{});
        const reader = &reader_wrapper.interface;

        while (reader.takeByte()) |byte| {
            if (isExitKey(byte)) {
                return;
            }
        } else |err| {
            std.log.err("TTY read error: {s}", .{@errorName(err)});
        }
    }
};

fn isExitKey(byte: u8) bool {
    return byte == ('c' & 0x1F) or byte == 'q';
}

// pub fn executeCommand(command: []const u8) !u32 {
//     return switch (tag) {
//         .linux, .macos => posixExec(.{ "sh", "-c", command }),
//         .windows => windowsExec(command),
//         else => @panic("unsupported OS"),
//     };
// }
//
// fn posixExec(command: anytype) !u32 {
//     const pid = try std.os.linux.fork();
//
//     if (pid == 0) {
//         // child process
//         _ = std.process.execve(std.heap.page_allocator, &command, null); // noreturn if success
//     }
//     // parent process
//     const wait_result = std.posix.waitpid(pid, 0);
//     return wait_result.status;
// }
//
// const windows = std.os.windows;
//
// fn windowsExec(command: []const u8) !windows.DWORD {
//     const cmd: [:0]const u16 = toUtf16Z: {
//         var buf: [256]u16 = undefined;
//         var buf_pos: u8 = 0;
//         for (command) |char| {
//             buf[buf_pos] = @intCast(char);
//             buf_pos += 1;
//         }
//         break :toUtf16Z try std.heap.page_allocator.dupeZ(u16, buf[0..buf_pos]);
//     };
//     defer std.heap.page_allocator.free(cmd);
//
//     const child_proc = spawn: {
//         var startup_info: windows.STARTUPINFOW = .{
//             .cb = @sizeOf(windows.STARTUPINFOW),
//             .lpReserved = null,
//             .lpDesktop = null,
//             .lpTitle = null,
//             .dwX = 0,
//             .dwY = 0,
//             .dwXSize = 0,
//             .dwYSize = 0,
//             .dwXCountChars = 0,
//             .dwYCountChars = 0,
//             .dwFillAttribute = 0,
//             .dwFlags = windows.STARTF_USESTDHANDLES,
//             .wShowWindow = 0,
//             .cbReserved2 = 0,
//             .lpReserved2 = null,
//             .hStdInput = null,
//             .hStdOutput = null,
//             .hStdError = windows.GetStdHandle(windows.STD_ERROR_HANDLE) catch null,
//         };
//
//         var proc_info: windows.PROCESS_INFORMATION = undefined;
//
//         try windows.CreateProcessW(
//             null,
//             @constCast(cmd.ptr),
//             null,
//             null,
//             windows.FALSE,
//             0,
//             null,
//             null,
//             &startup_info,
//             &proc_info,
//         );
//
//         windows.CloseHandle(proc_info.hThread);
//         defer windows.CloseHandle(proc_info.hProcess);
//
//         break :spawn proc_info.hProcess;
//     };
//     defer windows.CloseHandle(child_proc);
//
//     try windows.WaitForSingleObjectEx(child_proc, windows.INFINITE, false);
//
//     var exit_code: windows.DWORD = undefined;
//     if (windows.kernel32.GetExitCodeProcess(child_proc, &exit_code) == 0) {
//         return error.UnableToGetExitCode;
//     }
//
//     return exit_code;
// }

fn runTty(io: std.Io, writer: std.Io.File.Writer) !void {
    var tty = try TtyController.init(io, writer);
    defer tty.deinit(io);

    try tty.eventLoop(io);
}

pub fn main(init: std.process.Init) !void {
    const allocator: std.mem.Allocator = init.gpa;

    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buffer);
    const writer = &stdout_writer.interface;

    if (tag == .linux) {
        _ = try std.Thread.spawn(.{}, runTty, .{ init.io, stdout_writer });
    }
    const cmd = Command.parse(allocator, init.minimal.args) catch |err| {
        switch (err) {
            error.NoCommand => {
                std.log.err("expected command", .{});
                try writer.writeAll(printUsage());
                try writer.flush();
                return;
            },
            error.InvalidCommand => {
                std.log.err("invalid command", .{});
                try writer.writeAll(printUsage());
                try writer.flush();
                return;
            },
            error.MissingArgument => {
                std.log.err("missing argument", .{});
                try writer.writeAll(printUsage());
                try writer.flush();
                return;
            },
        }
    };

    const cmd_path = std.mem.span(init.minimal.args.vector[0]);
    try dispatch(init.io, cmd, allocator, writer, cmd_path);
}
// if (args.next()) |arg| {
//     if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "help")) {
//         std.debug.print(printUsage(), .{});
//     } else if (std.mem.eql(u8, arg, "init")) {
//         if (args.next()) |project_name| {
//             try initProject(project_name);
//         } else {
//             std.log.err("zframe init <project_name>", .{});
//         }
//     } else if (std.mem.eql(u8, arg, "build")) {
//         const status = try executeCommand("zig build run");
//         if (status == 0) {
//             try writer.interface.print("\x1B[1;92mBUILD SUCCESS.\x1B[m\n", .{});
//             try writer.interface.flush();
//         }
//         // try mdToHTML();
//         if (args.next()) |option| {
//             if (std.mem.eql(u8, option, "serve")) {
//                 try serve(writer);
//             } else if (std.mem.eql(u8, option, "-h")) {}
//         }
//     } else if (std.mem.eql(u8, arg, "update")) {
//         try updateDependencies();
//     } else {
//         std.log.err("Invalid command: {s}", .{arg});
//         std.debug.print(printUsage(), .{});
//     }
// } else {
//     log.err("expected command argument", .{});
//     std.debug.print(printUsage(), .{});
// }

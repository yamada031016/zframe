const std = @import("std");
const log = std.log;

const Allocator = std.mem.Allocator;

pub const Browser = struct {
    var browser_id: []const u8 = undefined;
    const domain = "http://localhost";

    allocator: std.mem.Allocator,
    io: std.Io,
    browser: []const u8 = "xdg-open",
    url: []const u8,
    app: WebBrowser,

    pub fn init(app: WebBrowser, allocator: Allocator, io: std.Io, port: u16) !Browser {
        const url = try std.fmt.allocPrint(allocator, "{s}:{}", .{ domain, port });
        return Browser{
            .allocator = allocator,
            .io = io,
            .browser = "xdg-open",
            .app = app,
            .url = url,
        };
    }

    pub fn deinit(self: *Browser) void {
        _ = &self;
        self.allocator.deinit();
    }

    pub fn openHtml(self: *Browser) !void {
        switch (@import("builtin").os.tag) {
            .linux => {
                const cmd = try std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ self.browser, self.url });
                _ = try std.process.run(self.allocator, self.io, .{ .argv = &[_][]const u8{ "sh", "-c", cmd } });
            },
            else => {},
        }
    }

    fn setActiveBrowserList(self: *Browser) !void {
        const outputFileName = "active-browser-list";
        const argv = &.{ "xdotool", "search", "--onlyvisible", "--name", self.app.asText(), ">", outputFileName };
        try self.launch(argv);
        var file = try std.fs.cwd().openFile(outputFileName, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();

        var buf: [1024]u8 = undefined;
        // get latest browser_id
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            browser_id = line;
        }
    }

    fn launch(self: *Browser, argv: anytype) !void {
        const fork_pid = try std.posix.fork();
        if (fork_pid == 0) {
            // child process
            const err = std.process.execve(self.allocator, argv, null); // noreturn if success
            log.err("{s}", .{@errorName(err)});
        } else {
            // parent process
            const wait_result = std.posix.waitpid(fork_pid, 0);
            if (wait_result.status != 0) {
                log.err("exit code: {}", .{wait_result.status});
            }
        }
    }
};

pub const WebBrowser = enum {
    firefox,
    chrome,

    pub fn asText(self: *WebBrowser) []const u8 {
        switch (self.*) {
            .firefox => return "firefox",
            .chrome => return "chrome",
        }
    }
};

const std = @import("std");
const log = std.log;

pub const Browser = struct {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var browser_id: []const u8 = undefined;
    const domain = "http://localhost";

    allocator: std.mem.Allocator,
    browser: []const u8 = "xdg-open",
    url: []const u8,
    app: WebBrowser,

    pub fn init(app: WebBrowser, port: u16) !Browser {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const url = try std.fmt.allocPrintZ(allocator, "{s}:{}", .{ domain, port });
        return Browser{ .allocator = arena_allocator.allocator(), .browser = "xdg-open", .app = app, .url = url };
    }

    pub fn deinit(self: *Browser) void {
        _ = &self;
        arena_allocator.deinit();
    }

    pub fn openHtml(self: *Browser) !void {
        const argv = &.{ self.browser, self.url };
        try self.launch(argv);
        // try self.setActiveBrowserList();
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

    pub fn reload(self: *Browser) !void {
        // const init_argv = &.{"xdotool", "windowfucus", "--sync", browser_id};
        // try self.launch(init_argv);
        // const reload_argv = &.{"xdotool", "key", "F5"};
        // try self.launch(reload_argv);
        // const reload_argv = &.{ "xdotool", "search", "--onlyvisible", "--name", "Chrome", "|", "xargs", "xdotool", "windowfocus", "--sync", ";", "xdotool", "key", "ctrl+r" };
        const reload_argv = &.{ "sh", "-c", "lastid=$(xdotool getactivewindow); xdotool search --onlyvisible --name Chrome | xargs xdotool windowfocus --sync ; xdotool key ctrl+r; xdotool windowfocus --sync $lastid " };
        try self.launch(reload_argv);
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

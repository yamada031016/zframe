const std = @import("std");
const log = std.log;
const IN = std.os.linux.IN;

pub const FileMonitor = struct {
    root_path: []const u8,
    monitors: Watcher,

    pub fn init(dir_path: []const u8) !FileMonitor {
        log.info("file-monitor watching {s}...\n", .{dir_path});
        var self = FileMonitor{
            .root_path = dir_path,
            .monitors = try Watcher.init(),
        };
        try self.monitors.addWatcherRecursive(dir_path);
        return self;
    }

    pub fn deinit(self: *FileMonitor) void {
        self.monitors.deinit();
    }

    pub fn detectChanges(self: *FileMonitor) !bool {
        const watch_info = try self.monitors.watch(self.root_path);
        switch (watch_info) {
            .create, .moveto => |path| {
                try self.monitors.addWatcherRecursive(path);
                return false;
            },
            .delete, .movefrom => |path| {
                try self.monitors.removeWatcher(path);
                return false;
            },
            // .movefrom, .moveto => |_| return false,
            .modified => return true,
        }
    }
};

const Watcher = union(enum) {
    inotify: Inotify,
    polling: Polling,

    pub fn init() !Watcher {
        switch (@import("builtin").os.tag) {
            .linux => return .{ .inotify = try Inotify.init() },
            else => return .{ .polling = try Polling.init() },
        }
    }

    pub fn deinit(self: *Watcher) void {
        switch (self.*) {
            .inotify => {
                // _ = std.os.linux.inotify_rm_watch(self.fd, self.watcher);
                _ = std.os.linux.close(self.inotify.fd);
            },
            .polling => {},
        }
    }

    pub fn addWatcherRecursive(self: *Watcher, dir_path: []const u8) !void {
        var root = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer root.close();
        var walker = try root.walk(std.heap.page_allocator);
        while (try walker.next()) |entry| {
            switch (entry.kind) {
                .directory => {
                    const target_path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ dir_path, entry.path });
                    if (!self.isMonitored(target_path)) {
                        try self.addWatch(target_path);
                    }
                },
                else => {},
            }
        }
    }

    fn addWatch(self: *Watcher, path: []const u8) !void {
        switch (self.*) {
            .inotify => return {
                const wd = try std.posix.inotify_add_watch(self.inotify.fd, path, IN.CREATE | IN.DELETE | IN.MODIFY | IN.MOVE_SELF | IN.MOVE);
                try self.inotify.monitor.put(path, wd);
            },
            .polling => {
                const weight = try self.polling.calculateDirWeight(path);
                try self.polling.monitor.put(path, weight);
            },
        }
    }

    fn isMonitored(self: *Watcher, file_path: []const u8) bool {
        switch (self.*) {
            .inotify => return self.inotify.monitor.contains(file_path),
            .polling => return self.polling.monitor.contains(file_path),
        }
    }

    pub fn removeWatcher(self: *Watcher, path: []const u8) !void {
        switch (self.*) {
            .inotify => return {
                const kv = self.inotify.monitor.fetchRemove(path).?;
                log.debug("{any}", .{kv});
            },
            .polling => {
                const kv = self.polling.monitor.fetchRemove(path).?;
                log.debug("{any}", .{kv});
            },
        }
    }

    pub fn watch(self: *Watcher, path: []const u8) !WatchInfo {
        switch (self.*) {
            .inotify => |inotify| {
                return try inotify.watch(path);
            },
            .polling => |polling| {
                return try polling.watch(path);
            },
        }
    }
};

const WatchInfo = union(WatchState) {
    const WatchState = enum {
        create,
        delete,
        movefrom,
        moveto,
        modified,
    };
    create: []const u8,
    delete: []const u8,
    movefrom: []const u8,
    moveto: []const u8,
    modified: void,
};

const Inotify = struct {
    fd: i32,
    monitor: std.StringHashMap(i32),
    pub fn init() !Inotify {
        const fd = try std.posix.inotify_init1(0);
        return .{
            .fd = fd,
            .monitor = std.StringHashMap(i32).init(std.heap.page_allocator),
        };
    }

    pub fn watch(self: *const Inotify, root_path: []const u8) !WatchInfo {
        while (true) {
            var buf: [256]u8 = undefined;
            if (std.posix.read(self.fd, &buf)) |len| {
                var event = @as(*std.os.linux.inotify_event, @ptrCast(@alignCast(buf[0..len])));
                switch (event.mask) {
                    IN.CREATE | IN.ISDIR => {
                        log.info("created {s}", .{event.getName().?});
                        const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ root_path, event.getName().? });
                        return WatchInfo{ .create = path };
                    },
                    IN.DELETE | IN.ISDIR => {
                        log.info("deleted {s}", .{event.getName().?});
                        const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ root_path, event.getName().? });
                        return WatchInfo{ .delete = path };
                    },
                    IN.MODIFY => {
                        log.info("modified {s}", .{event.getName().?});
                        return WatchInfo{ .modified = {} };
                    },
                    IN.MOVED_FROM => {
                        const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ root_path, event.getName().? });
                        return WatchInfo{ .movefrom = path };
                    },
                    IN.MOVED_TO => {
                        const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ root_path, event.getName().? });
                        return WatchInfo{ .moveto = path };
                    },
                    // IN.MOVE_SELF => {
                    //     const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ self.root_path, event.getName().? });
                    //     return WatchInfo{ .moved = path };
                    // },
                    // IN.MOVE => {
                    //     const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ self.root_path, event.getName().? });
                    //     return WatchInfo{ .moved = path };
                    // },
                    else => {},
                }
            } else |err| {
                return err;
            }
        }
    }
};

pub const Polling = struct {
    monitor: std.StringHashMap(i128),

    pub fn init() !Polling {
        return .{
            .monitor = std.StringHashMap(i128).init(std.heap.page_allocator),
        };
    }

    pub fn watch(self: *const Polling, path: []const u8) !WatchInfo {
        var root = try std.fs.cwd().openDir(path, .{ .iterate = true });
        defer root.close();
        var walker = try root.walk(std.heap.page_allocator);
        while (true) {
            while (try walker.next()) |entry| {
                std.time.sleep(50 * 10 ^ 6); // 50 ms
                switch (entry.kind) {
                    .directory => {
                        const dir_path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ path, entry.path });
                        const weight = try self.calculateDirWeight(dir_path);
                        if (self.monitor.get(dir_path)) |prev_weight| {
                            if (prev_weight != weight) {
                                return .{ .modified = {} };
                            }
                        } else {
                            return .{ .create = path };
                        }
                    },
                    else => {},
                }
            }
        }
    }

    pub fn calculateDirWeight(_: *const Polling, dir_path: []const u8) !i128 {
        var root = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer root.close();
        var walker = try root.walk(std.heap.page_allocator);
        var weight: i128 = 0;
        while (try walker.next()) |entry| {
            switch (entry.kind) {
                .file => {
                    const path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ dir_path, entry.path });
                    if (root.openFile(path, .{})) |file| {
                        const stat = try file.stat();
                        weight += stat.size + stat.mtime;
                    } else |err| {
                        switch (err) {
                            // ファイルが空だと起こる
                            error.FileNotFound => {},
                            else => return err,
                        }
                    }
                },
                else => {},
            }
        }
        return weight;
    }
};

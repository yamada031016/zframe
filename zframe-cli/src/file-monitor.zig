const std = @import("std");
const log = std.log;
const IN = std.os.linux.IN;

const Inotify = struct {
    monitor: std.StringHashMap(i32),
    pub fn init(_: *Inotify) Inotify {
        return std.StringHashMap(i32);
    }
};

const Polling = struct {
    pub fn init(_: *Polling) Polling {
        return std.StringHashMap(i32);
    }
};

pub const FileMonitor = struct {
    root_path: []const u8,
    fd: i32,
    monitors: switch (@import("builtin").os.tag) {
        .linux => Inotify,
        else => Polling,
    },

    pub fn init(dir_path: []const u8) !FileMonitor {
        log.info("file-monitor watching {s}...\n", .{dir_path});
        const fd = try std.posix.inotify_init1(0);
        var self = FileMonitor{
            .root_path = dir_path,
            .fd = fd,
            // .monitors = std.StringHashMap(i32).init(std.heap.page_allocator),
            .monitors = switch (@import("builtin").os.tag) {
                .linux => .{ .monitor = std.StringHashMap(i32).init(std.heap.page_allocator) },
                else => .{},
            },
        };
        try self.addMonitor(dir_path);
        return self;
    }

    pub fn deinit(self: *FileMonitor) void {
        // _ = std.os.linux.inotify_rm_watch(self.fd, self.watcher);
        _ = std.os.linux.close(self.fd);
    }

    fn addMonitor(self: *FileMonitor, path: []const u8) !void {
        // std.debug.print("dir:{s}\n", .{path});
        const wd = try std.posix.inotify_add_watch(self.fd, path, IN.CREATE | IN.DELETE | IN.MODIFY | IN.MOVE_SELF | IN.MOVE);
        try self.monitors.put(path, wd);

        var root = try std.fs.cwd().openDir(path, .{ .iterate = true });
        defer root.close();
        var walker = try root.walk(std.heap.page_allocator);
        while (try walker.next()) |entry| {
            switch (entry.kind) {
                .directory => {
                    const target_path = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ path, entry.path });
                    if (!self.monitors.contains(target_path)) {
                        try self.addMonitor(target_path);
                    }
                },
                else => {},
            }
        }
    }

    fn removeMonitor(self: *FileMonitor, path: []const u8) !void {
        const kv = self.monitors.fetchRemove(path).?;
        log.info("{any}", .{kv});
        //
        // var root = try std.fs.cwd().openDir(path, .{.iterate=true});
        // defer root.close();
        // var walker = try root.walk(alloc);
        // while (try walker.next()) |entry| {
        //     switch(entry.kind) {
        //         .directory => {
        //             // std.debug.print("dir:{s}\n", .{try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{path, entry.path})});
        //             try self.addMonitor(try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{path, entry.path}));
        //         },
        //         else => {},
        //     }
        // }
    }

    pub fn detectChanges(self: *FileMonitor) bool {
        var buf: [256]u8 = undefined;
        while (true) {
            if (std.posix.read(self.fd, &buf)) |len| {
                var event = @as(*std.os.linux.inotify_event, @ptrCast(@alignCast(buf[0..len])));
                switch (event.mask) {
                    IN.CREATE | IN.ISDIR => {
                        const path = std.fmt.allocPrintZ(std.heap.page_allocator, "{s}/{s}", .{ self.root_path, event.getName().? }) catch {
                            return false;
                        };
                        log.info("created {s},\tpath: {s}", .{ event.getName().?, path });
                        self.addMonitor(self.root_path) catch {
                            return false;
                        };
                    },
                    IN.DELETE | IN.ISDIR => {
                        log.info("deleted {s}", .{event.getName().?});
                        // const path = std.fmt.allocPrintZ(alloc, "{s}/{s}", .{self.root_path, event.getName().?}) catch {
                        //     return false;
                        // };
                        // self.removeMonitor(path) catch {
                        //     return false;
                        // };
                    },
                    IN.MODIFY => {
                        log.info("modified {s}", .{event.getName().?});
                    },
                    IN.MOVE_SELF => {},
                    IN.MOVE => {},
                    else => {},
                }
                return true;
            } else |e| {
                log.err("{s}", .{@errorName(e)});
            }
        }
    }
};

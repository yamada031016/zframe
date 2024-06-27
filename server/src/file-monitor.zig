const std = @import("std");

pub const FileMonitor = struct {
    var meta: std.fs.File.Stat = undefined;
    dir: std.fs.Dir,
    fileName: []const u8,
    size: u64,
    last_modified: i128,

    pub fn init(fileName: []const u8, dir:std.fs.Dir) !FileMonitor {
        std.debug.print("monitor init fileName:{s}\n", .{fileName});
        const file = try dir.openFile(fileName, .{});
        defer file.close();
        const stat = try file.stat();
        var self = FileMonitor {
            .dir = dir,
            .fileName = fileName,
            .size = stat.size,
            .last_modified = stat.mtime,
        };
        _=&self;
        return self;
    }

    pub fn detectChanges(self: *FileMonitor) !bool {
        if (self.dir.openFile(self.fileName, .{})) |file| {
            meta = try file.stat();
            if (self.size != meta.size and self.last_modified != meta.mtime) {
                std.debug.print("detect!\n", .{});
                self.size = meta.size;
                self.last_modified = meta.mtime;
                return true;
            } else {
                return false;
            }
        } else |err| {
            switch (err) {
                // ファイルが空だと起こる
                error.FileNotFound => return false,
                else => {
                    std.debug.print("{s}\n", .{@errorName(err)});
                    return err;
                },
            }
        }
    }
};

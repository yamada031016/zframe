const std = @import("std");

pub const FileMonitor = struct {
    fileName: []const u8,
    size: u64,
    last_modified: i128,

    pub fn init(fileName: []const u8) !FileMonitor {
        const cwd = std.fs.cwd();
        var file = try cwd.openFile(fileName, .{});
        var stat = try file.stat();
        _ = &stat;
        var self = FileMonitor{
            .fileName = fileName,
            .size = stat.size,
            .last_modified = stat.mtime,
        };
        _ = &self;
        return self;
    }

    pub fn hasChanges(self: *FileMonitor) !bool {
        const cwd = std.fs.cwd();
        var file = try cwd.openFile(self.fileName, .{});
        const meta = try file.stat();
        if (self.size != meta.size or self.last_modified != meta.mtime) {
            self.size = meta.size;
            self.last_modified = meta.mtime;
            return true;
        } else {
            return false;
        }
    }
};

const std = @import("std");

const FileMonitor = struct {
    var meta: std.fs.File.Stat = undefined;
    var file: std.fs.File = undefined;
    fileName: []const u8,
    size: u64,
    last_modified: i128,

    pub fn init(fileName: []const u8) !FileMonitor {
        file = try std.fs.cwd().openFile(fileName, .{});
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
        if (std.fs.cwd().openFile(self.fileName, .{})) |_file| {
            file = _file;
        } else |err| {
            switch (err) {
                // ファイルが空だと起こる
                error.FileNotFound => return false,
                else => std.debug.print("{s}\n", .{@errorName(err)}),
            }
        }
        meta = try file.stat();
        if (self.size != meta.size and self.last_modified != meta.mtime) {
            self.size = meta.size;
            self.last_modified = meta.mtime;
            return true;
        } else {
            return false;
        }
    }
};

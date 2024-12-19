//! 便利な関数たち
const std = @import("std");
const leb128 = @import("leb128.zig");

pub fn readFileAll(path: []const u8, buf: []u8) !usize {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    return try reader.readAll(@constCast(buf));
}

pub fn isWasmFile(file_path: []const u8) bool {
    for (file_path, 0..) |char, i| {
        if (char == '.') {
            if (std.mem.eql(u8, file_path[i + 1 ..], "wasm")) {
                return true;
            }
        }
    }
    return false;
}

// calcArgWidthと一緒
pub fn getValCounts(data: []u8, pos: usize) usize {
    var tmp = [_]u8{0} ** 4;
    for (data[pos..], 0..) |val, j| {
        tmp[j] = val;
        if (val < 128) {
            break;
        }
    }

    return leb128.decodeLEB128(&tmp);
}

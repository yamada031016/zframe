const std = @import("std");

pub const Mime = enum {
    html,
    css,
    map,
    svg,
    jpg,
    png,
    wasm,
    other,

    pub fn asMime(filePath: []const u8) Mime {
        const file_ext = extractFileExtension(filePath);
        // 超雑な変換
        return switch (file_ext[1]) {
            'h' => .html,
            'c' => .css,
            'm' => .map,
            's' => .svg,
            'j' => .jpg,
            'p' => .png,
            'w' => .wasm,
            else => .other,
        };
    }
    pub fn asText(self: *const Mime) []const u8 {
        return switch (self.*) {
            .html => "text/html",
            .css => "text/css",
            .map => "application/json",
            .svg => "image/svg+xml",
            .jpg => "image/jpg",
            .png => "image/png",
            .wasm => "application/wasm",
            .other => "text/plain",
        };
    }

    fn extractFileExtension(filePath:[]const u8) []const u8 {
        var file_ext = std.fs.path.extension(filePath);
        if (file_ext.len == 0) {
            // /hogeのとき.htmlを補完する
            file_ext = ".html";
        }
        return file_ext;
    }
};

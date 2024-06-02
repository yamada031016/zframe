const std = @import("std");
const Element = @import("element.zig").Element;

pub fn render(id: []const u8, args: anytype) !void {
    _ = id;
    if (args.len == 0) return;
    var index = try std.fs.cwd().createFile("index.html", .{});
    var writer = index.writer();
    try writer.writeAll(
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\<script src="https://cdn.tailwindcss.com"></script>
        \\<meta charset="utf-8" />
        \\<title>WebAssembly</title>
        \\</head>
    );
    defer index.close();

    try writer.writeAll("\n<body>");
    inline for (args) |node| {
        // try parse(node, @constCast(&writer));
        try parse((&node), @constCast(&writer));
    }
    try writer.print("</body></html>", .{});
}

fn parse(code: *const Element, writer: *std.fs.File.Writer) !void {
    switch (@typeInfo(@TypeOf(code))) {
        // .Pointer => {},
        else => {
            const tag = code.tag.asText();
            if (code.class.len != 0) {
                // std.debug.print("class! {any}\n", .{code.class});
                try writer.print("<{s} class=\"{s}\">", .{ tag, code.class });
            } else {
                try writer.print("<{s}>", .{tag});
            }
            if (code.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            if (code.child) |child| {
                // std.debug.print("child:{any}\n", .{code});
                // try parse((child[0].*), writer);
                try parse(((child)), writer);
            }

            try writer.print("</{s}>", .{tag});
        },
    }
}

const std = @import("std");
const Element = @import("element.zig").Element;
const n = @import("node.zig");
const Node = n.Node;

// pub fn render(id: []const u8, args: anytype) !void {
pub fn render(id: []const u8, args: anytype) !void {
    _ = id;

    const root = n.createNode(.div).init(args);
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
        \\<script type="module">const env = { memory: new WebAssembly.Memory({initial: 2, maximum: 2}),};var memory = env.memory; WebAssembly.instantiateStreaming( fetch("monitor.wasm"),{env}).then(obj => {if(obj.instance.exports.monitor()) {}});</script>

    );
    defer index.close();

    try writer.writeAll("\n<body>");
    try parse(&root, @constCast(&writer));
    try writer.print("</body></html>", .{});
}

fn parse(node: *const Node, writer: *std.fs.File.Writer) !void {
    switch (node.elem) {
        .plane => |*plane| {
            const tag = plane.tag.asText();
            if (node.getClass()) |class| {
                try writer.print("<{s} class=\"{s}\"", .{ tag, class });
            } else {
                try writer.print("<{s}", .{tag});
            }
            if (plane.id) |_id| {
                try writer.print("id=\"{s}\">", .{ _id });
            } else {
                try writer.print(">", .{});
            }
            if (plane.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            for (node.children.items) |child| {
                try parse(&child, writer);
            }

            try writer.print("</{s}>", .{tag});
        },
        .image => |*image| {
            const src = image.src orelse @panic("Image Element must have image path argument.");
            try writer.print("<img src=\"{s}\"", .{ src });
            if(image.alt) |alt| {
                try writer.print("alt=\"{s}\"", .{ alt });
            }
            if (node.getClass()) |class| {
                try writer.print("class=\"{s}\"", .{class });
            }
            if (image.id) |_id| {
                try writer.print("id=\"{s}\">", .{ _id });
            } else {
                try writer.print(">", .{});
            }
        },
        .link => |*link| {
            const href = link.href orelse @panic("Link Element must have hyperlink argument.");
            try writer.print("<a href=\"{s}\"", .{ href });
            if (node.getClass()) |class| {
                try writer.print("class=\"{s}\"", .{ class });
            }
            if (link.id) |_id| {
                try writer.print("id=\"{s}\">", .{ _id });
            } else {
                try writer.print(">", .{});
            }
            if (link.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            for (node.children.items) |child| {
                try parse(&child, writer);
            }

            try writer.print("</a>", .{});
        },
    }
}

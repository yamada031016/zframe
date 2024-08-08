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
                // std.debug.print("class! {s}\n", .{class});
                try writer.print("id=\"{s}\">", .{ _id });
            } else {
                try writer.print(">", .{});
            }
            if (plane.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            // if (code.child) |child| {
            for (node.children.items) |child| {
                // if (code.children) |children| {
                //     for (children) |child| {
                // std.debug.print("cld:{any}\n", .{(child)});
                // const children_slice = try @constCast(&code.children).toOwnedSlice();
                // for (children_slice) |child| {
                // std.debug.print("child:{any}\n", .{code});
                // try parse((child[0].*), writer);
                try parse(&child, writer);
                // }
            }

            try writer.print("</{s}>", .{tag});
        },
        .image => |*image| {
            const src = image.src orelse @panic("Image Element must have image path argument.");
            try writer.print("<img src=\"{s}\"", .{ src });
            if(image.alt) |alt| {
                try writer.print("alt=\"{s}\"", .{ alt });
            }
            try writer.print(">", .{});
        }
    }
}

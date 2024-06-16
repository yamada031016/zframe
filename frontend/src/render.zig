const std = @import("std");
const Element = @import("element.zig").Element;
const n = @import("node.zig");
const Node = n.Node;

// pub fn render(id: []const u8, args: anytype) !void {
pub fn render(id: []const u8, args: anytype) !void {
    _ = id;

    const root = n.createNode(.div).init(args);
    // if (args.len == 0) return;
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
    // inline for (args) |node| {
    try parse(&root, @constCast(&writer));
    // try parse((&node), @constCast(&writer));
    // }
    try writer.print("</body></html>", .{});
}

// fn parse(code: *const Element, writer: *std.fs.File.Writer) !void {
fn parse(node: *const Node, writer: *std.fs.File.Writer) !void {
    var elem = node.elem;
    switch (@typeInfo(@TypeOf(elem))) {
        // .Pointer => {},
        else => {
            const tag = elem.tag.asText();
            if (elem.class) |class| {
                std.debug.print("class! {s}\n", .{class});
                try writer.print("<{s} class=\"{s}\">", .{ tag, class });
            } else {
                try writer.print("<{s}>", .{tag});
            }
            if (elem.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            // if (code.child) |child| {
            for (node.children.items) |child| {
                // if (code.children) |children| {
                //     for (children) |child| {
                std.debug.print("cld:{any}\n", .{(child)});
                // const children_slice = try @constCast(&code.children).toOwnedSlice();
                // for (children_slice) |child| {
                // std.debug.print("child:{any}\n", .{code});
                // try parse((child[0].*), writer);
                try parse(&child, writer);
                // }
            }

            try writer.print("</{s}>", .{tag});
        },
    }
}

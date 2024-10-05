const std = @import("std");
const z = @import("ssg-zig");
const Element = @import("element.zig").Element;
const n = @import("node.zig");
const Node = n.Node;

const RenderError = error{
    InvalidPageFilePath,
};

var html_output_path: []u8 = @constCast("zig-out/html/");

fn generateHtmlFile(id: std.builtin.SourceLocation) !std.fs.File {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const src = std.fs.path.dirname(id.file) orelse return RenderError.InvalidPageFilePath; // expect "src/pages"
    const parent = std.fs.path.basename(src); // parent dir of the page component file. ex) pages/, about/

    if (std.mem.eql(u8, parent, "pages")) {
        // single file routing.
        // ex) pages/index.zig, pages/about.zig.
        if (std.fs.path.dirname(src)) |_| {
            const url = std.fs.path.stem(std.fs.path.basename(id.file));
            return try std.fs.cwd().createFile(try std.fmt.allocPrintZ(allocator, "zig-out/html/{s}.html", .{url}), .{ .read = true });
        }
    } else if (!std.mem.eql(u8, parent, "src") and std.mem.eql(u8, std.fs.path.basename(id.file), "page.zig")) {
        // multiple file routing.
        // ex) pages/about/page.zig, pages/about/contact/page.zig
        const url = parent;
        var parent_dir = std.fs.path.dirname(src).?;
        while (!std.mem.eql(u8, std.fs.path.basename(parent_dir), "pages")) {
            html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, std.fs.path.basename(parent_dir) });
            var output_dir = try std.fs.cwd().makeOpenPath(html_output_path, .{ .iterate = true });
            try output_dir.chmod(0o777);
            output_dir.close();
            parent_dir = std.fs.path.dirname(parent_dir).?;
        }
        const fileName = try std.fmt.allocPrintZ(allocator, "{s}.html", .{url});
        html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, fileName });
        return try std.fs.cwd().createFile(html_output_path, .{ .read = true });
    }
    return RenderError.InvalidPageFilePath;
}

pub fn render(id: std.builtin.SourceLocation, args: Node) !void {
    // std.debug.print("File: {s}\n", .{id.file});
    const html = generateHtmlFile(id) catch |e| switch (e) {
        RenderError.InvalidPageFilePath => {
            std.debug.print("invalid file path: {s}. move below src/pages/**", .{id.file});
            return;
        },
        else => return,
    };
    try html.chmod(0o777);
    defer {
        html.close();
    }

    // var root = applicateLayout: {
    //     std.fs.cwd().access("src/components/layout.zig", .{}) catch {
    //         break :applicateLayout n.createNode(.div).setId("root").init(.{args});
    //     };
    //     // break :applicateLayout n.createNode(.div).setId("root").init(.{@import("components").layout.Layout(args)});
    // };
    var root = n.createNode(.div).setId("root").init(.{args});
    var writer = html.writer();

    try writer.writeAll("\n<body>");
    try parse(&root, @constCast(&writer));
    try writer.print("</body>", .{});

    const head_file = std.fs.cwd().openFile(".zig-cache/head.html", .{ .mode = .read_write }) catch {
        const tmp = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .read = true });
        const len = try html.getEndPos();
        _ = try std.fs.File.copyRangeAll(html, 0, tmp, 0, len);
        const tmp_len = try tmp.getEndPos();
        const offset = try html.pwrite("<!DOCTYPE html>", 0);
        _ = try std.fs.File.copyRangeAll(tmp, 0, html, offset, tmp_len);
        return;
    };
    try head_file.writer().writeAll("</head>");
    // tmp.htmlはheadタグの内容を保持
    // bodyタグを保持するhtmlをtmp.htmlに追記
    // htmlの先頭にDOCTYPEを記述し、その分のoffsetを開けてtmp.htmlの内容をhtmlにコピーする
    const len = try html.getEndPos();
    var head_len = try head_file.getEndPos();
    _ = try std.fs.File.copyRangeAll(html, 0, head_file, head_len, len);
    head_len = try head_file.getEndPos();
    const offset = try html.pwrite("<!DOCTYPE html>", 0);
    _ = try std.fs.File.copyRangeAll(head_file, 0, html, offset, head_len);
    try std.fs.cwd().deleteFile(".zig-cache/head.html");
}

fn parse(node: *const Node, writer: *std.fs.File.Writer) !void {
    switch (node.elem) {
        .plane => |*plane| {
            switch (plane.tag) {
                .empty, .raw => {
                    if (plane.template) |temp| {
                        try writer.print("{s}", .{temp});
                    }
                    for (node.children.items) |child| {
                        try parse(&child, writer);
                    }
                },
                else => {
                    const tag = plane.tag.asText();
                    if (std.mem.eql(u8, tag, "head")) {
                        // headタグの内容をtmp.htmlに避難
                        var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .read = true });
                        var head_writer = head_output.writer();
                        try head_writer.print("\n<head>", .{});
                        for (node.children.items) |child| {
                            try parse(&child, &head_writer);
                        }
                    } else {
                        if (node.class) |class| {
                            try writer.print("<{s} class=\"{s}\"", .{ tag, class });
                        } else {
                            try writer.print("<{s}", .{tag});
                        }

                        if (node.id) |_id| {
                            try writer.print(" id=\"{s}\">", .{_id});
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
                    }
                },
            }
        },
        .image => |*image| {
            const src = image.src orelse @panic("Image Element must have image path argument.");
            try writer.print("<img src=\"{s}\"", .{src});
            if (image.alt) |alt| {
                try writer.print("alt=\"{s}\"", .{alt});
            }
            if (node.class) |class| {
                try writer.print("class=\"{s}\"", .{class});
            }
            if (image.width) |w| {
                try writer.print("width=\"{}\"", .{w});
            }
            if (image.height) |h| {
                try writer.print("height=\"{}\"", .{h});
            }
            if (node.id) |_id| {
                try writer.print("id=\"{s}\">", .{_id});
            } else {
                try writer.print(">", .{});
            }
        },
        .hyperlink => |*hyperlink| {
            const href = hyperlink.href orelse @panic("HyperLink Element must have hyperlink argument.");
            try writer.print("<a href=\"{s}\"", .{href});
            if (node.class) |class| {
                try writer.print("class=\"{s}\"", .{class});
            }
            if (node.id) |_id| {
                try writer.print("id=\"{s}\">", .{_id});
            } else {
                try writer.print(">", .{});
            }
            if (hyperlink.template) |temp| {
                try writer.print("{s}", .{temp});
            }

            for (node.children.items) |child| {
                try parse(&child, writer);
            }

            try writer.print("</a>", .{});
        },
        .link => |*link| {
            const rel = link.rel orelse @panic("Link Element must have rel and href argument.");
            try writer.print("<link rel=\"{s}\"", .{rel});
            if (link.href) |href| {
                try writer.print("href=\"{s}\"", .{href});
            }
            try writer.print(">", .{});
        },
        .meta => |*meta| {
            const meta_type = meta.meta_type orelse @panic("Meta Element have no arguments");
            switch (meta_type) {
                .charset => try writer.print("<meta charset=\"{s}\"", .{meta.charset.?}),
                .property => try writer.print("<meta property=\"{s}\"content=\"{s}\"", .{ meta.property.?, meta.content.? }),
                else => try writer.print("<meta name=\"{s}\"content=\"{s}\"", .{ meta_type.asText(), meta.content.? }),
            }
            try writer.print(">", .{});
        },
        .custom => |*custom| {},
    }
}

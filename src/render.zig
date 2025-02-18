const std = @import("std");
const mem = std.mem;
const htmlZig = @import("html.zig");
const element = @import("element.zig");
const Element = element.Element;
const n = @import("node.zig");
const Node = n.Node;
const markdown = @import("zframe.zig").markdown;

const RenderError = error{
    InvalidPageFilePath,
    UnsupportedFileExtension,
};

fn generateHtmlFile(dir_name: []const u8, page_name: []const u8) !std.fs.File {
    var buffer: [32]u8 = undefined;
    var fixedBufferAllocator = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fixedBufferAllocator.allocator();
    var html_output_path: []u8 = @constCast(dir_name);

    if (std.fs.path.dirname(page_name)) |dir| {
        var parent_dir = dir;
        while (std.fs.path.dirname(parent_dir)) |d| {
            html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, std.fs.path.basename(d) });
            var output_dir = try std.fs.cwd().makeOpenPath(html_output_path, .{ .iterate = true });
            output_dir.close();
            parent_dir = d;
        }
    }
    const fileName = try std.fmt.allocPrint(allocator, "{s}.html", .{std.fs.path.stem(page_name)}); // src/pages/hoge/a.md -> a.html
    html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, fileName }); // src/pages/hoge/a.md -> $output_dir/hoge/a.html
    return try std.fs.cwd().createFile(html_output_path, .{ .read = true });
}

// fn generateHtmlFile(dir_name: []const u8, page_name: []const u8) !std.fs.File {
//     var buffer: [32]u8 = undefined;
//     var fixedBufferAllocator = std.heap.FixedBufferAllocator.init(&buffer);
//     const allocator = fixedBufferAllocator.allocator();
//
//     const src = std.fs.path.dirname(page_name) orelse return RenderError.InvalidPageFilePath; // src/pages/index.zig -> src/pages
//     const parent = std.fs.path.basename(src); // src/pages -> pages
//     var html_output_path: []u8 = @constCast("zig-out/html/");
//
//     if (mem.eql(u8, parent, "pages")) {
//         // single file routing.
//         // ex) pages/index.zig, pages/about.zig.
//         if (std.fs.path.dirname(src)) |_| {
//             const url = std.fs.path.stem(std.fs.path.basename(page_name));
//             return try std.fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/{s}.html", .{ dir_name, url }), .{ .read = true });
//         }
//     } else {
//         // multiple file routing.
//         // ex) pages/about/page.zig, pages/about/contact.md
//         if (mem.eql(u8, std.fs.path.basename(page_name), "page.zig")) {
//             const url = parent;
//             var parent_dir = std.fs.path.dirname(src).?;
//             while (!mem.eql(u8, std.fs.path.basename(parent_dir), "pages")) {
//                 html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, std.fs.path.basename(parent_dir) });
//                 var output_dir = try std.fs.cwd().makeOpenPath(html_output_path, .{ .iterate = true });
//                 output_dir.close();
//                 parent_dir = std.fs.path.dirname(parent_dir).?;
//             }
//             const fileName = try std.fmt.allocPrint(allocator, "{s}.html", .{url});
//             html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, fileName });
//             return try std.fs.cwd().createFile(html_output_path, .{ .read = true });
//         } else if (mem.eql(u8, std.fs.path.extension(page_name), ".md")) {
//             std.log.err("{s}\n", .{src});
//             var parent_dir = std.fs.path.dirname(src).?;
//             // pages/hoge/fuga -> pages/hoge -> pages
//             while (!mem.eql(u8, std.fs.path.basename(parent_dir), "pages")) {
//                 html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, std.fs.path.basename(parent_dir) });
//                 var output_dir = try std.fs.cwd().makeOpenPath(html_output_path, .{ .iterate = true });
//                 output_dir.close();
//                 parent_dir = std.fs.path.dirname(parent_dir).?;
//             }
//             const fileName = try std.fmt.allocPrint(allocator, "{s}.html", .{std.fs.path.stem(page_name)}); // src/pages/hoge/a.md -> a.html
//             html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, fileName }); // src/pages/hoge/a.md -> $output_dir/hoge/a.html
//             return try std.fs.cwd().createFile(html_output_path, .{ .read = true });
//         }
//     }
//     return RenderError.InvalidPageFilePath;
// }

pub fn renderMarkdown(md_filename: []const u8, layout: ?std.fs.File) !void {
    const html = generateHtmlFile("zig-out/html", md_filename) catch |e| switch (e) {
        RenderError.InvalidPageFilePath => {
            std.log.err("{s} {s}  move below src/pages/**", .{ @errorName(e), md_filename });
            return e;
        },
        else => return e,
    };
    defer html.close();

    const file = try std.fs.cwd().openFile(try std.fmt.allocPrint(std.heap.page_allocator, "src/pages/{s}", .{md_filename}), .{});
    var md_buf: [5 * 1024]u8 = undefined;
    const idx = try file.reader().readAll(&md_buf);

    const result = try markdown.parser.parse_markdown(md_buf[0..idx]);

    const writer = html.writer();
    var hc = markdown.html.converter(writer);

    if (layout) |l| {
        const layoutContents = readAll: {
            var buf: [1024 * 5]u8 = undefined;
            const l_len = try l.readAll(&buf);
            if (l_len < buf.len) {
                break :readAll buf[0..l_len];
            } else {
                @panic("layout buffer overflow");
            }
        };

        const z_pos = std.mem.indexOfPos(u8, layoutContents, 0, "ℤ") orelse 0;
        try writer.writeAll(layoutContents[0..z_pos]);
        try hc.mdToHTML(result.result);
        try writer.writeAll(layoutContents[z_pos + "ℤ".len ..]);
    } else {
        try hc.mdToHTML(result.result);
    }
}

pub fn render(page_name: []const u8, args: Node) !void {
    const html = generateHtmlFile("zig-out/html", page_name) catch |e| switch (e) {
        RenderError.InvalidPageFilePath => {
            std.log.err("{s} {s}  move below src/pages/**", .{ @errorName(e), page_name });
            return e;
        },
        else => return e,
    };
    defer html.close();

    const layout: ?std.fs.File = l: {
        std.fs.cwd().access(".zig-cache/layout.html", .{}) catch break :l null;
        break :l try std.fs.cwd().openFile(".zig-cache/layout.html", .{});
    };
    var root = n.createNode(.div).setId("root").init(.{args});
    var writer = html.writer();

    try writer.writeAll("\n<body>");
    if (layout) |l| {
        const layoutContents = readAll: {
            var buf: [1024 * 5]u8 = undefined;
            const l_len = try l.readAll(&buf);
            if (l_len < buf.len) {
                break :readAll buf[0..l_len];
            } else {
                @panic("layout buffer overflow");
            }
        };
        const z_pos = std.mem.indexOfPos(u8, layoutContents, 0, "ℤ") orelse 0;
        try writer.writeAll(layoutContents[0..z_pos]);
        try parse(&root, writer);
        try writer.writeAll(layoutContents[z_pos + 3 ..]);
    } else {
        try parse(&root, writer);
    }
    try writer.print("</body></html>", .{});

    const head_file = std.fs.cwd().openFile(".zig-cache/head.html", .{ .mode = .read_write }) catch {
        const tmp = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .read = true });
        const len = try html.getEndPos();
        _ = try std.fs.File.copyRangeAll(html, 0, tmp, 0, len);
        const tmp_len = try tmp.getEndPos();
        const offset = try html.pwrite("<!DOCTYPE html>", 0);
        _ = try std.fs.File.copyRangeAll(tmp, 0, html, offset, tmp_len);
        return;
    };

    const len = try html.getEndPos();
    var head_len = try head_file.getEndPos();
    _ = try std.fs.File.copyRangeAll(html, 0, head_file, head_len, len);
    head_len = try head_file.getEndPos();
    const offset = try html.pwrite("<!DOCTYPE html>", 0);
    _ = try std.fs.File.copyRangeAll(head_file, 0, html, offset, head_len);
    try std.fs.cwd().deleteFile(".zig-cache/head.html");
}

fn parse(node: *const Node, writer: anytype) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // var buf: []u8 = buffer;
    switch (node.elem) {
        .custom => {
            if (node.is) |is| {
                const fileName = try std.fmt.allocPrint(allocator, "zig-out/html/webcomponents/{s}.js", .{is});
                std.fs.cwd().access(fileName, .{}) catch recover: {
                    const output = try std.fs.cwd().createFile(fileName, .{});
                    try generateWebComponents(node, output.writer());
                    break :recover;
                };

                // std.fs.cwd().access(fileName, .{}) catch {
                //     const head = try std.fs.cwd().createFile(".zig-cache/head.html", .{});
                //     const head_writer = head.writer();
                //     try head_writer.print("\n<head>", .{});
                // };
                var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
                const wb_loader = try std.fmt.allocPrint(allocator, "<script type='module'src='webcomponents/{s}'defer></script>", .{std.fs.path.basename(fileName)});
                try head_output.pwriteAll(wb_loader, try head_output.getEndPos());
                try writer.print("<div is=\"{s}\"></div>", .{is});
            } else {
                std.debug.panic("custom element must have is field.\n{any}\n", .{node});
            }
        },
        .meta => |*meta| {
            const meta_type = meta.meta_type orelse @panic("Meta Element have no arguments");
            switch (meta_type) {
                .charset => try writer.print("<meta charset=\"{s}\"", .{meta.charset.?}),
                .property => try writer.print("<meta property=\"{s}\"content=\"{s}\"", .{ meta.property.?, meta.content.? }),
                else => try writer.print("<meta name=\"{s}\"content=\"{s}\"", .{ @tagName(meta_type), meta.content.? }),
            }
            try writer.writeAll(">");
        },
        else => |elem| {
            const tagName = elem.getTagName();
            if (mem.eql(u8, "raw", tagName) or mem.eql(u8, "empty", tagName)) {
                if (elem.plane.template) |temp| {
                    try writer.print("{s}", .{temp});
                }
                for (node.children.items) |child| {
                    try parse(&child, writer);
                }
            } else if (mem.eql(u8, "head", tagName)) {
                var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .read = true });
                defer head_output.close();
                var head_writer = head_output.writer();
                try head_writer.writeAll("\n<head>");
                for (node.children.items) |child| {
                    try parse(&child, head_writer);
                }
                try head_writer.writeAll("</head>");
            } else {
                try parseElement(node, writer);
                for (node.children.items) |child| {
                    try parse(&child, writer);
                }
                try writer.print("</{s}>", .{tagName});
            }
        },
    }
    for (node.loadContents.items) |loader| {
        var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
        switch (loader) {
            .webassembly => |wasm| {
                if (wasm.handler.then) |then| {
                    try head_output.pwriteAll(try std.fmt.allocPrint(allocator, "<script type='text/javascript' src='js/{s}'></script>", .{then.filename}), try head_output.getEndPos());
                }
                const js = try wasm.toJavaScript();
                try head_output.pwriteAll(try std.fmt.allocPrint(allocator, "<script>{s}</script>", .{js}), try head_output.getEndPos());
            },
            .javascript => {},
        }
    }
    if (node.listener.count() != 0) {
        var iter = node.listener.iterator();
        while (iter.next()) |it| {
            var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
            switch (it.value_ptr.content) {
                .javascript => |js| {
                    try head_output.pwriteAll(try std.fmt.allocPrint(allocator, "<script type='text/javascript' src='js/{s}'></script>", .{js.filename}), try head_output.getEndPos());
                    try writer.print("<script>document.getElementsByClassName(\"{}\")[0].addEventListener(\"{s}\",()=>{{{s}()}})</script>", .{
                        it.key_ptr.*,
                        @tagName(it.value_ptr.*.target),
                        js.func,
                    });
                },
                .webassembly => |wasm| {
                    if (wasm.handler.then) |then| {
                        try head_output.pwriteAll(try std.fmt.allocPrint(allocator, "<script type='text/javascript' src='js/{s}'></script>", .{then.filename}), try head_output.getEndPos());
                    }
                    const js = try wasm.toJavaScript();
                    try writer.print("<script>document.addEventListener('DOMContentLoaded',()=>{{document.getElementsByClassName(\"{}\")[0].addEventListener(\"{s}\",()=>{{{s}}})}})</script>", .{
                        it.key_ptr.*,
                        @tagName(it.value_ptr.*.target),
                        js,
                    });
                },
            }
        }
    }
    // return try allocator.dupe(u8, buf);
}

fn parseElement(node: *const n.Node, writer: anytype) !void {
    const tagName = node.elem.getTagName();
    try writer.print("<{s}", .{tagName});
    const nodeInfo = @typeInfo(@TypeOf(node.*));
    inline for (nodeInfo.Struct.fields) |field| {
        if (@hasField(@TypeOf(node.*), field.name)) {
            const fieldValue = @field(node.*, field.name);
            if (@TypeOf(fieldValue) == ?[]u8) {
                if (fieldValue) |f| {
                    try writer.print(" {s}=\"{s}\"", .{ field.name, f });
                }
            }
        }
    }
    const elem_buf = switch (node.elem) {
        .plane => |p| try parseElementHelper(p),
        .image => |i| try parseElementHelper(i),
        .hyperlink => |h| try parseElementHelper(h),
        .link => |l| try parseElementHelper(l),
        .form => |l| try parseElementHelper(l),
        .input => |l| try parseElementHelper(l),
        .tablecol => |l| try parseElementHelper(l),
        .th => |l| try parseElementHelper(l),
        .td => |l| try parseElementHelper(l),
        else => @panic("unsupported element"),
    };
    try writer.print(" {s}", .{elem_buf});
}

inline fn parseElementHelper(elem: anytype) ![]u8 {
    const elemInfo = @typeInfo(@TypeOf(elem));
    var buf: []u8 = "";
    var isClosed = false;
    inline for (elemInfo.Struct.fields) |field| {
        if (@hasField(@TypeOf(elem), field.name)) {
            const fieldValue = @field(elem, field.name);
            if (@typeInfo(@TypeOf(fieldValue)) == .Optional) {
                if (fieldValue) |f| {
                    switch (@typeInfo(@TypeOf(f))) {
                        .Pointer, .Array => {
                            if (std.mem.eql(u8, "template", field.name)) {
                                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}>{s}", .{ buf, fieldValue orelse "" });
                                isClosed = true;
                            } else {
                                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}=\"{s}\"{s}", .{ field.name, f, buf });
                            }
                        },
                        .Bool => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}=\"{}\"{s}", .{ field.name, f, buf }),
                        .Int => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}=\"{d}\"{s}", .{ field.name, f, buf }),
                        .EnumLiteral, .Enum => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}=\"{s}\"{s}", .{ field.name, @tagName(f), buf }),
                        else => {},
                    }
                }
            }
        }
    }
    if (!isClosed) {
        buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}>", .{buf});
    }
    return std.heap.page_allocator.dupe(u8, buf);
}

fn generateWebComponents(node: *const n.Node, writer: anytype) !void {
    const webcomponents_template = "customElements.define('{s}',class extends HTMLDivElement{{constructor(){{super();this.attachShadow({{mode:'open'}});this._data=[]}}set data(value){{this._data=value;this.render()}}connectedCallback(){{this.render()}}render(){{this.shadowRoot.innerHTML=`";
    if (node.is) |is| {
        try writer.print(webcomponents_template, .{is});
    }
    for (node.children.items) |child| {
        try generateJsElement(&child, writer);
    }
    try writer.writeAll("`");
    if (node.listener.count() != 0) {
        // var iter = node.listener.iterator();
        // while (iter.next()) |it| {
        // if (std.mem.eql(u8, it.key_ptr.*, "webassembly")) {
        //     if (it.value_ptr.webassembly.then) |then| {
        //         var head_output = try std.fs.cwd().openFile(".zig-cache/head.html", .{ .mode = .read_write });
        //         try head_output.pwriteAll(try std.fmt.allocPrint(std.heap.page_allocator, "<script type='text/javascript' src='{s}'></script>", .{then.filename}), try head_output.getEndPos());
        //     }
        //     const js = try it.value_ptr.*.webassembly.toJS();
        //     try writer.writeAll(try std.fmt.allocPrint(std.heap.page_allocator, "this.addEventListener('click',()=>{{{s}}})", .{js}));
        // }
        // }
    }
    try writer.writeAll("}},{extends:'div'})");
}

fn generateJsElement(node: *const n.Node, writer: anytype) !void {
    try parseElement(node, writer);
    for (node.children.items) |child| {
        try generateJsElement(&child, writer);
    }
    try writer.print("</{s}>", .{node.elem.getTagName()});
}

pub fn config(layout: fn (Node) Node) !void {
    const cwd = std.fs.cwd();
    const layoutFile = try cwd.createFile(".zig-cache/layout.html", .{});
    const writer = layoutFile.writer();
    const raw = n.createNode(.raw).init("ℤ");
    try parse(&layout(raw), writer);

    const _layout: ?std.fs.File = l: {
        std.fs.cwd().access(".zig-cache/layout.html", .{}) catch break :l null;
        break :l try std.fs.cwd().openFile(".zig-cache/layout.html", .{});
    };
    const dir = try cwd.openDir("src/pages/", .{ .iterate = true });
    var walker = try dir.walk(std.heap.page_allocator);
    while (try walker.next()) |file| {
        switch (file.kind) {
            .file => {
                if (std.mem.eql(u8, ".md", std.fs.path.extension(file.path))) {
                    try renderMarkdown(file.path, _layout);
                } else {}
            },
            else => {},
        }
    }
}

test "generateWebComponents" {
    const h1 = n.createNode(.h1).setId("testId").setClass("test testClass").init(.{"test text content here!"});
    const custom = n.createNode(.custom);
    const test_text = custom.setId("test-text").init(.{h1});

    var result: [128 * 4]u8 = undefined;
    var buf = std.io.fixedBufferStream(&result);
    try generateWebComponents(&test_text, buf.writer());
    try std.testing.expectEqualStrings("customElements.define('test-text',class extends HTMLDivElement{constructor(){super();const shadowRoot=this.attachShadow({mode:'open'});const h1=document.createElement('h1');h1.className='test testClass';h1.id='testId';h1.textContent='test text content here!';shadowRoot.appendChild(h1).cloneNode(true);}},{extends:'div'})", result[0..buf.pos]);
}

test "generateJsElement" {
    const h1 = n.createNode(.h1).setId("testId").setClass("test testClass").init(.{"test text content here!"});
    const result = try generateJsElement(h1);
    try std.testing.expectEqualStrings("const h1=document.createElement('h1');h1.className='test testClass';h1.id='testId';h1.textContent='test text content here!';", result);
}

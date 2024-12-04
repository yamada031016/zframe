const std = @import("std");
const mem = std.mem;
const z = @import("ssg-zig");
const htmlZig = @import("html.zig");
const element = @import("element.zig");
const Element = element.Element;
const n = @import("node.zig");
const Node = n.Node;

const RenderError = error{
    InvalidPageFilePath,
};

fn generateHtmlFile(dir_name: []const u8, page_name: []const u8) !std.fs.File {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const src = std.fs.path.dirname(page_name) orelse return RenderError.InvalidPageFilePath; // expect "src/pages"
    const parent = std.fs.path.basename(src); // parent dir of the page component file. ex) pages/, about/
    var html_output_path: []u8 = @constCast("zig-out/html/");

    if (mem.eql(u8, parent, "pages")) {
        // single file routing.
        // ex) pages/index.zig, pages/about.zig.
        if (std.fs.path.dirname(src)) |_| {
            const url = std.fs.path.stem(std.fs.path.basename(page_name));
            return try std.fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/{s}.html", .{ dir_name, url }), .{ .read = true });
        }
    } else if (!mem.eql(u8, parent, "src") and mem.eql(u8, std.fs.path.basename(page_name), "page.zig")) {
        // multiple file routing.
        // ex) pages/about/page.zig, pages/about/contact/page.zig
        const url = parent;
        var parent_dir = std.fs.path.dirname(src).?;
        while (!mem.eql(u8, std.fs.path.basename(parent_dir), "pages")) {
            html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, std.fs.path.basename(parent_dir) });
            var output_dir = try std.fs.cwd().makeOpenPath(html_output_path, .{ .iterate = true });
            try output_dir.chmod(0o777);
            output_dir.close();
            parent_dir = std.fs.path.dirname(parent_dir).?;
        }
        const fileName = try std.fmt.allocPrint(allocator, "{s}.html", .{url});
        html_output_path = try std.fs.path.join(allocator, &[_][]const u8{ html_output_path, fileName });
        return try std.fs.cwd().createFile(html_output_path, .{ .read = true });
    }
    return RenderError.InvalidPageFilePath;
}

pub fn render(page_name: []const u8, args: Node) !void {
    const html = generateHtmlFile("zig-out/html", page_name) catch |e| switch (e) {
        RenderError.InvalidPageFilePath => {
            std.debug.panic("invalid file path: {s} . move below src/pages/**", .{page_name});
            return;
        },
        else => return,
    };
    try html.chmod(0o777);
    defer html.close();

    const layout: ?std.fs.File = l: {
        std.fs.cwd().access(".zig-cache/layout.html", .{}) catch break :l null;
        break :l try std.fs.cwd().openFile(".zig-cache/layout.html", .{});
    };
    var root = n.createNode(.div).setId("root").init(.{args});
    var writer = html.writer();

    try writer.writeAll("\n<body>");
    if (layout) |l| {
        const layoutContents = try l.readToEndAlloc(std.heap.page_allocator, 1024 * 5);
        const z_pos = std.mem.indexOfPos(u8, layoutContents, 0, "ℤ") orelse 0;
        try writer.writeAll(layoutContents[0..z_pos]);
        const dom = try parse(&root, "");
        try writer.writeAll(dom);
        try writer.writeAll(layoutContents[z_pos + 3 ..]);
    } else {
        const dom = try parse(&root, "");
        try writer.writeAll(dom);
    }
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
    // try head_file.writer().writeAll("</head>");
    try head_file.pwriteAll("</head>", try head_file.getEndPos());
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

fn parse(node: *const Node, buffer: []u8) ![]u8 {
    var buf = buffer;
    switch (node.elem) {
        .custom => {
            if (node.is) |is| {
                const fileName = try std.fmt.allocPrint(std.heap.page_allocator, "zig-out/html/webcomponents/{s}.js", .{is});
                std.fs.cwd().access(fileName, .{}) catch recover: {
                    const output = try std.fs.cwd().createFile(fileName, .{});
                    try generateWebComponents(node, output.writer());
                    break :recover;
                };

                std.fs.cwd().access(fileName, .{}) catch {
                    const head = try std.fs.cwd().createFile(".zig-cache/head.html", .{});
                    const head_writer = head.writer();
                    try head_writer.print("\n<head>", .{});
                };
                var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
                const wb_loader = try std.fmt.allocPrint(std.heap.page_allocator, "<script type='module'src='webcomponents/{s}'defer></script>", .{std.fs.path.basename(fileName)});
                try head_output.pwriteAll(wb_loader, try head_output.getEndPos());
                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<div is=\"{s}\"></div>", .{ buf, is });
            } else {
                std.debug.panic("custom element must have is field.\n{any}\n", .{node});
            }
        },
        .meta => |*meta| {
            const meta_type = meta.meta_type orelse @panic("Meta Element have no arguments");
            switch (meta_type) {
                .charset => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<meta charset=\"{s}\"", .{ buf, meta.charset.? }),
                .property => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<meta property=\"{s}\"content=\"{s}\"", .{ buf, meta.property.?, meta.content.? }),
                else => buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<meta name=\"{s}\"content=\"{s}\"", .{ buf, meta_type.asText(), meta.content.? }),
            }
            buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}>", .{buf});
        },
        else => |elem| {
            const tagName = node.elem.getTagName();
            if (mem.eql(u8, "raw", tagName) or mem.eql(u8, "empty", tagName)) {
                if (elem.plane.template) |temp| {
                    buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ buf, temp });
                }
                for (node.children.items) |child| {
                    buf = try parse(&child, try std.heap.page_allocator.dupe(u8, buf));
                }
            } else if (mem.eql(u8, "head", tagName)) {
                var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .read = true });
                defer head_output.close();
                var head_writer = head_output.writer();
                try head_writer.print("\n<head>", .{});
                var head_buf: []u8 = "";
                for (node.children.items) |child| {
                    head_buf = try parse(&child, head_buf);
                }
                try head_writer.print("<head>{s}</head>", .{head_buf});
                return "";
            } else {
                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<{s}", .{ buf, tagName });
                const nodeInfo = @typeInfo(@TypeOf(node.*));
                inline for (nodeInfo.Struct.fields) |field| {
                    if (@hasField(@TypeOf(node.*), field.name)) {
                        const fieldValue = @field(node.*, field.name);
                        if (@TypeOf(fieldValue) == ?[]u8) {
                            if (fieldValue) |f| {
                                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}=\"{s}\"", .{ buf, field.name, f });
                            }
                        }
                    }
                }
                const elem_buf = switch (elem) {
                    .plane => |p| try parseElement(p),
                    .image => |i| try parseElement(i),
                    .hyperlink => |h| try parseElement(h),
                    .link => |l| try parseElement(l),
                    else => unreachable,
                };
                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ buf, elem_buf });
                for (node.children.items) |child| {
                    buf = try parse(&child, try std.heap.page_allocator.dupe(u8, buf));
                }
                buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}</{s}>", .{ buf, tagName });
            }
        },
    }
    for (node.loadContents.items) |loader| {
        var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
        switch (loader) {
            .webassembly => |wasm| {
                if (wasm.handler.then) |then| {
                    try head_output.pwriteAll(try std.fmt.allocPrint(std.heap.page_allocator, "<script type='text/javascript' src='js/{s}'></script>", .{then.filename}), try head_output.getEndPos());
                }
                const js = try wasm.toJavaScript();
                try head_output.pwriteAll(try std.fmt.allocPrint(std.heap.page_allocator, "<script>{s}</script>", .{js}), try head_output.getEndPos());
            },
            .javascript => {},
        }
    }
    if (node.listener.count() != 0) {
        var iter = node.listener.iterator();
        while (iter.next()) |it| {
            // switch (it.value_ptr.target) {
            //     .click => {
            var head_output = try std.fs.cwd().createFile(".zig-cache/head.html", .{ .truncate = false });
            switch (it.value_ptr.content) {
                .javascript => |js| {
                    try head_output.pwriteAll(try std.fmt.allocPrint(std.heap.page_allocator, "<script type='text/javascript' src='js/{s}'></script>", .{js.filename}), try head_output.getEndPos());
                    buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<script>document.getElementById(\"{}\").addEventListener(\"{s}\",()=>{{{s}()}})</script>", .{
                        buf,
                        it.key_ptr.*,
                        @tagName(it.value_ptr.*.target),
                        js.func,
                    });
                },
                .webassembly => |wasm| {
                    if (wasm.handler.then) |then| {
                        try head_output.pwriteAll(try std.fmt.allocPrint(std.heap.page_allocator, "<script type='text/javascript' src='js/{s}'></script>", .{then.filename}), try head_output.getEndPos());
                    }
                    const js = try wasm.toJavaScript();
                    buf = try std.fmt.allocPrint(std.heap.page_allocator, "{s}<script>document.addEventListener('DOMContentLoaded',()=>{{document.getElementById(\"{}\").addEventListener(\"{s}\",()=>{{{s}()}})}})</script>", .{
                        buf,
                        it.key_ptr.*,
                        @tagName(it.value_ptr.*.target),
                        js,
                    });
                },
            }
            //     },
            //     else => {},
            // }
        }
    }
    return try std.heap.page_allocator.dupe(u8, buf);
}

inline fn parseElement(elem: anytype) ![]u8 {
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
                        else => std.debug.print("{any}\n", .{f}),
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
    const webcomponents_template = "customElements.define('{s}',class extends HTMLDivElement{{constructor(){{super();const shadowRoot=this.attachShadow({{mode:'open'}});";
    if (node.is) |is| {
        try writer.print(webcomponents_template, .{is});
    }
    for (node.children.items) |child| {
        try writer.writeAll(try generateJsElement(child));
        for (child.children.items) |c| {
            try writer.writeAll(try generateJsElement(c));
        }
        try writer.print("shadowRoot.appendChild({s}).cloneNode(true);", .{child.elem.getTagName()});
    }
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

inline fn generateJsElement(node: n.Node) ![]const u8 {
    const tag = node.elem.getTagName();
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    var writer = buf.writer();
    try writer.print("const {s}=document.createElement('{s}');", .{ tag, tag });

    if (node.class) |class| {
        try writer.print("{s}.className='{s}';", .{ tag, class });
    }
    if (node.id) |id| {
        try writer.print("{s}.id='{s}';", .{ tag, id });
    }
    if (node.elem.getTemplate()) |temp| {
        try writer.print("{s}.textContent='{s}';", .{ tag, temp });
    } else |e| {
        std.debug.print("{s}\n{s} element does not support template.\n", .{ @errorName(e), tag });
    }
    return try buf.toOwnedSlice();
}

pub fn config(layout: fn (Node) Node) !void {
    const cwd = std.fs.cwd();
    const layoutFile = try cwd.createFile(".zig-cache/layout.html", .{});
    const writer = layoutFile.writer();
    const raw = n.createNode(.raw).init("ℤ");
    const dom = try parse(&layout(raw), "");
    try writer.writeAll(dom);
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

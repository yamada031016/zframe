const std = @import("std");

pub fn createElement(tagName: Tag) Element {
    return .{
        .tag = tagName,
    };
}

const Element = struct {
    const Self = @This();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    tag: Tag,
    template: ?[]const u8 = null,
    child: ?*const Self = null,
    class: ?[]const u8 = null,

    // pub fn init(self: *const Self, comptime string: []const u8, comptime args: anytype) Self {
    pub fn init(self: *const Self, args: anytype) Self {
        var tmp = Self{
            .tag = self.tag,
            .template = null,
            .child = null,
        };

        inline for (args, 0..) |arg, i| {
            switch (@typeInfo(@TypeOf(arg))) {
                .Pointer => |pointer| {
                    if (@typeInfo(pointer.child) == .Array) {
                        // stringとみなす
                        if (i < args.len - 1) {
                            // format string
                            tmp.template = std.fmt.allocPrint(alloc, arg, args[i + 1]) catch @panic("hoge");
                        } else {
                            // 続くargがなければ非フォーマット文字列
                            // tmp.template = std.fmt.allocPrint(alloc, arg, .{}) catch @panic("hoge");
                            tmp.template = arg;
                        }
                    }
                },
                .Struct => {
                    if (@TypeOf(arg) == Element) {
                        tmp.child = &arg;
                    }
                },
                else => {},
            }
        }

        std.debug.print("tag:{s}\n", .{tmp.tag.asText()});
        return tmp;
    }

    pub fn setClass(self: *const Self, css: []const u8) Self {
        return .{
            .tag = self.tag,
            .template = self.template,
            .child = self.child,
            .class = css,
        };
    }
};

pub fn render(id: []const u8, args: anytype) !void {
    _ = id;
    if (args.len == 0) return;
    var index = try std.fs.cwd().createFile("index.html", .{});
    var writer = index.writer();
    try writer.writeAll(
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\<meta charset="utf-8" />
        \\<title>WebAssembly</title>
        \\</head>
    );
    defer index.close();

    try writer.writeAll("<body>");
    inline for (args) |node| {
        try parse(node, writer);
    }
    try writer.print("</body></html>", .{});
}

fn parse(code: Element, writer: std.fs.File.Writer) !void {
    switch (@typeInfo(@TypeOf(code))) {
        .Pointer => {},
        else => {
            const tag = code.tag.asText();
            try writer.print("<{s} class=\"{s}\">{s}", .{ tag, code.class orelse "", code.template orelse "" });
            // try writer.print("<{s}>{s}", .{ tag, code.template orelse "" });

            if (code.child) |child| {
                try parse(child.*, writer);
            }
            try writer.print("</{s}>", .{tag});
        },
    }
}

pub const Tag = enum {
    html,
    div,
    heading,
    p,

    pub fn asText(tag: Tag) []const u8 {
        return switch (tag) {
            .html => "html",
            .div => "div",
            .heading => "h1",
            .p => "p",
        };
    }
};
// \\<script type="module">
// \\const env = {
// \\memory: new WebAssembly.Memory({initial: 2, maximum: 2}),
// \\};
// \\var memory = env.memory
// \\WebAssembly.instantiateStreaming(
// \\fetch("../zig-out/bin/hello.wasm"),
// \\{env}
// \\).then(obj => {
// \\var buf = new Uint32Array(memory.buffer, 0, 2)
// \\obj.instance.exports.set(buf)
// \\obj.instance.exports.hello()
// \\const mem = new Uint8Array(memory.buffer, buf[0], buf[1]);
// \\const dec = new TextDecoder();
// \\const hello = dec.decode(mem)
// \\console.log(hello)
// \\document.getElementById("output").textContent = hello
// \\});
// \\</script>

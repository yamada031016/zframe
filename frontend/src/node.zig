const std = @import("std");
const elem = @import("./element.zig");
const Element = elem.Element;
const Tag = @import("html.zig").Tag;

pub fn createNode(comptime tagName: Tag) Node {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const node = Node{
        .elem = elem.createElement(tagName),
        .children = std.ArrayList(Node).init(allocator),
    };
    return node;
}

pub const Node = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    elem: Element,
    children: std.ArrayList(Node),

    pub fn init(self: *const Node, args: anytype) Node {
        var tmp = Node{
            .elem = self.elem,
            .children = std.ArrayList(Node).init(alloc),
        };
        inline for (args, 0..) |arg, i| {
            switch (@typeInfo(@TypeOf(arg))) {
                .Pointer => |pointer| {
                    if (@typeInfo(pointer.child) == .Array) {
                        if (i < args.len - 1) {
                            // stringとみなす
                            tmp.elem.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("hoge"));
                        } else {
                            // 続くargがなければ非フォーマット文字列
                            tmp.elem.template = @constCast(arg);
                        }
                    } else if (pointer.child == u8) {
                        tmp.elem.template = @constCast(arg);
                    }
                },
                .Struct => {
                    if (@TypeOf(arg) == Node) {
                        tmp.children.append(arg) catch |e| switch (e) {
                            else => @panic("failed to append children"),
                        };
                    } else if (@TypeOf(arg) == Element) {
                        const node = Node{
                            .elem = arg,
                            .children = std.ArrayList(Node).init(alloc),
                        };
                        tmp.children.append(node) catch |e| switch (e) {
                            else => @panic("failed to append children"),
                        };
                    }
                },
                else => {},
            }
        }
        std.debug.print("tmp:{any}\n", .{tmp});
        return tmp;
    }

    pub fn setClass(self: *const Node, comptime css: []const u8) Node {
        return Node{
            .children = self.children,
            .elem = self.elem.setClass(css),
        };
    }

    pub fn deinit(self: *Node) void {
        _ = self;
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("Memory leaked");
    }

    pub fn addChild(self: *Node, value: i32) !void {
        var child = try Node.init(alloc, value);
        try self.children.append(&child);
    }
};

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

    class: ?[]u8 = null,
    id: ?[]u8 = null,

    pub fn init(self: *const Node, args: anytype) Node {
        var tmp = Node{
            .elem = self.elem,
            .class = self.class,
            .id = self.id,
            .children = std.ArrayList(Node).init(alloc),
        };
        switch(tmp.elem) {
            .plane => |*plane| {
                inline for (args, 0..) |arg, i| {
                    switch (@typeInfo(@TypeOf(arg))) {
                        .Pointer => |pointer| {
                            if (@typeInfo(pointer.child) == .Array) {
                                if (i < args.len - 1) {
                                    // stringとみなす
                                    plane.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("hoge"));
                                } else {
                                    // 続くargがなければ非フォーマット文字列
                                    plane.*.template = @constCast(arg);
                                }
                            } else if (pointer.child == u8) {
                                plane.*.template = @constCast(arg);
                            }
                        },
                        .Struct => {
                            if (@TypeOf(arg) == Node) {
                                tmp.children.append(arg) catch |e| switch (e) {
                                    else => @panic("failed to append children"),
                                };
                            } else if (@TypeOf(arg) == Element) {
                                const node = Node{
                                    .elem = Element{.plane = arg},
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
            },

            .image => |*image| {
                inline for (args) |arg| {
                    switch (@typeInfo(@TypeOf(arg))) {
                        .Pointer => |pointer| {
                            if (@typeInfo(pointer.child) == .Array) {
                                // if (i < args.len - 1 and @typeInfo(@TypeOf(args[i+1])) == .Struct) {
                                //     // stringとみなす
                                //     // srcが未設定ならsrcと判定. srcが設定済みだとaltと判定
                                //     // argsはsrc, altの順番で渡す必要がある
                                //     // .{.src ="src"}のように渡したいが、画像タグ以外のargsも何故か実行されてエラーが出る(謎)
                                //         if(image.src) |_| {
                                //             image.*.alt = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i+1]) catch @panic("hoge"));
                                //         } else {
                                //             image.*.src = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i+1]) catch @panic("hoge"));
                                //         }
                                // } else {
                                    // 続くargがなければ非フォーマット文字列
                                    if(image.src) |_| {
                                        image.*.alt = @constCast(arg);
                                    } else {
                                        image.*.src = @constCast(arg);
                                    }
                                // }
                            } else if (pointer.child == u8) {
                                if(image.src) |_| {
                                    image.*.alt = @constCast(arg);
                                } else {
                                    image.*.src = @constCast(arg);
                                }
                            }
                        },
                        else => {},
                    }
                }
            },
            .link => |*link| {
                inline for (args, 0..) |arg, i| {
                    switch (@typeInfo(@TypeOf(arg))) {
                        .Pointer => |pointer| {
                            if (@typeInfo(pointer.child) == .Array) {
                                if (i < args.len - 1 and @typeInfo(@TypeOf(args[i+1])) == .Struct) {
                                if(link.href) |_| {
                                    link.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i+1]) catch @panic("hoge"));
                                } else {
                                    link.*.href = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i+1]) catch @panic("hoge"));
                                }

                                } else {
                                if(link.href) |_| {
                                    link.*.template = @constCast(arg);
                                } else {
                                    link.*.href = @constCast(arg);
                                }
                                }
                            } else if (pointer.child == u8) {
                                if(link.href) |_| {
                                    link.*.template = @constCast(arg);
                                } else {
                                    link.*.href = @constCast(arg);
                                }
                            }
                        },
                        .Struct => {
                            if (@TypeOf(arg) == Node) {
                                tmp.children.append(arg) catch |e| switch (e) {
                                    else => @panic("failed to append children"),
                                };
                            } else if (@TypeOf(arg) == Element) {
                                const node = Node{
                                    .elem = Element{.plane = arg},
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
            },
        }
        return tmp;
    }

    pub fn setClass(self: *const Node, comptime class_name: []const u8) Node {
        var tmp = self.*;
        tmp.class = @constCast(class_name);
        return tmp;
    }

    pub fn getClass(self:*const Node) ?[]u8 {
        return self.class;
    }

    pub fn setId(self: *const Node, comptime id_name: []const u8) Node {
        var tmp = self.*;
        tmp.id = @constCast(id_name);
        return tmp;
    }


    pub fn deinit(self: *Node) void {
        _ = self;
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("Memory leaked");
    }
};

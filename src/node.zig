//! This module provides structures and functions for managing Element structures.
const std = @import("std");
const elem = @import("element.zig");
const Element = elem.Element;
const Tag = @import("html.zig").Tag;
const h = @import("handler.zig");
const JsHandler = h.JsHandler;
const Loader = h.Loader;

/// This function returns Node structures which contains proper Element union.
pub fn createNode(comptime tagName: Tag) Node {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const node = Node{
        .elem = elem.createElement(tagName),
        .children = std.ArrayList(Node).init(allocator),
        .loadContents = std.ArrayList(Loader).init(allocator),
        .handlers = std.AutoHashMap(h.Events, h.JsWrapper).init(allocator),
    };
    return node;
}

/// This structures is manager for Element.
/// Node manages Element and its children relationship.
/// In addition, it manages the class and id fields of the element.
pub const Node = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    elem: Element,
    children: std.ArrayList(Node),
    handlers: std.AutoHashMap(h.Events, h.JsWrapper),
    loadContents: std.ArrayList(Loader),
    class: ?[]u8 = null,
    id: ?[]u8 = null,

    pub fn init(self: *const Node, args: anytype) Node {
        var tmp = Node{
            .elem = self.elem,
            .class = self.class,
            .id = self.id,
            .handlers = std.AutoHashMap(h.Events, h.JsWrapper).init(alloc),
            .loadContents = std.ArrayList(Loader).init(alloc),
            .children = std.ArrayList(Node).init(alloc),
        };
        switch (tmp.elem) {
            .plane => |*plane| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {
                            inline for (args, 0..) |arg, i| {
                                switch (@typeInfo(@TypeOf(arg))) {
                                    .Pointer => |pointer| {
                                        if (@typeInfo(pointer.child) == .Array) {
                                            if (i < args.len - 1) {
                                                // stringとみなす
                                                plane.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("failed to format template string."));
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
                                        }
                                    },
                                    .Void => {},
                                    else => self.fatal(NodeError.invalidArgs, args),
                                }
                            }
                        } else {
                            // inline for (s.fields) |field| {
                            //     if (@hasField(@TypeOf(plane), field.name)) {
                            //         @field(plane, field.name) = @field(args, field.name);
                            //     } else {
                            //         self.fatal(NodeError.invalidArgs, args);
                            //     }
                            // }
                            inline for (@field(@TypeOf(plane.*), "attributes")) |attr| {
                                if (@hasField(@TypeOf(args), attr)) {
                                    if (@field(plane, attr) == null) {
                                        switch (@typeInfo(@TypeOf(@field(args, attr)))) {
                                            .Pointer => @field(plane, attr) = @constCast(@field(args, attr)),
                                            else => @field(plane, attr) = @field(args, attr),
                                        }
                                    }
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
                                }
                            }
                        }
                    },
                    else => |e| {
                        if (e == .Array or e == .Pointer) {
                            // expect args as string
                            plane.*.template = @constCast(args);
                        }
                    },
                }
            },
            .image => |*image| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {} else {
                            inline for (@field(@TypeOf(image.*), "attributes")) |attr| {
                                if (@hasField(@TypeOf(args), attr)) {
                                    if (@field(image, attr) == null) {
                                        switch (@typeInfo(@TypeOf(@field(args, attr)))) {
                                            .Pointer => @field(image, attr) = @constCast(@field(args, attr)),
                                            else => @field(image, attr) = @field(args, attr),
                                        }
                                    }
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
                                }
                            }
                        }
                    },
                    else => self.fatal(NodeError.invalidArgs, args),
                }
            },
            .hyperlink => |*hyperlink| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {
                            inline for (args, 0..) |arg, i| {
                                switch (@typeInfo(@TypeOf(arg))) {
                                    .Pointer => |pointer| {
                                        if (@typeInfo(pointer.child) == .Array) {
                                            if (i < args.len - 1 and @typeInfo(@TypeOf(args[i + 1])) == .Struct) {
                                                if (hyperlink.href) |_| {
                                                    hyperlink.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("failed to format template string."));
                                                } else {
                                                    hyperlink.*.href = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("failed to format hyper reference string."));
                                                    if (args.len < 3) {
                                                        hyperlink.*.template = hyperlink.*.href;
                                                    }
                                                }
                                            } else {
                                                if (hyperlink.href) |_| {
                                                    hyperlink.*.template = @constCast(arg);
                                                } else {
                                                    hyperlink.*.href = @constCast(arg);
                                                    if (args.len < 2) {
                                                        hyperlink.*.template = hyperlink.*.href;
                                                    }
                                                }
                                            }
                                        } else if (pointer.child == u8) {
                                            if (hyperlink.href) |_| {
                                                hyperlink.*.template = @constCast(arg);
                                            } else {
                                                hyperlink.*.href = @constCast(arg);
                                                if (args.len < 2) {
                                                    hyperlink.*.template = hyperlink.*.href;
                                                }
                                            }
                                        }
                                    },
                                    .Struct => {
                                        if (@TypeOf(arg) == Node) {
                                            tmp.children.append(arg) catch |e| switch (e) {
                                                else => @panic("failed to append children"),
                                            };
                                        }
                                    },
                                    else => self.fatal(NodeError.invalidArgs, args),
                                }
                            }
                        } else {
                            inline for (@field(@TypeOf(hyperlink.*), "attributes")) |attr| {
                                if (@hasField(@TypeOf(args), attr)) {
                                    if (@field(hyperlink, attr) == null) {
                                        switch (@typeInfo(@TypeOf(@field(args, attr)))) {
                                            .Pointer => @field(hyperlink, attr) = @constCast(@field(args, attr)),
                                            else => @field(hyperlink, attr) = @field(args, attr),
                                        }
                                    }
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
                                }
                            }
                        }
                    },
                    else => self.fatal(NodeError.invalidArgs, args),
                }
            },
            .link => |*link| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {
                            inline for (args) |arg| {
                                switch (@typeInfo(@TypeOf(arg))) {
                                    .Pointer => |pointer| {
                                        if (@typeInfo(pointer.child) == .Array) {
                                            if (link.rel) |_| {
                                                link.*.href = @constCast(arg);
                                            } else {
                                                link.*.rel = @constCast(arg);
                                            }
                                        } else if (pointer.child == u8) {
                                            if (link.rel) |_| {
                                                link.*.href = @constCast(arg);
                                            } else {
                                                link.*.rel = @constCast(arg);
                                            }
                                        }
                                    },
                                    else => self.fatal(NodeError.invalidArgs, args),
                                }
                            }
                        } else {
                            inline for (@field(@TypeOf(link.*), "attributes")) |attr| {
                                if (@hasField(@TypeOf(args), attr)) {
                                    if (@field(link, attr) == null) {
                                        switch (@typeInfo(@TypeOf(@field(args, attr)))) {
                                            .Pointer => @field(link, attr) = @constCast(@field(args, attr)),
                                            else => @field(link, attr) = @field(args, attr),
                                        }
                                    }
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
                                }
                            }
                        }
                    },
                    else => self.fatal(NodeError.invalidArgs, args),
                }
            },
            .meta => |*meta| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {
                            if (args.len < 2)
                                @panic("meta element must have 2 arguments.");
                            inline for (args, 0..) |arg, i| {
                                switch (@typeInfo(@TypeOf(arg))) {
                                    .EnumLiteral => {
                                        const metaType = @as(elem.Meta.MetaType, arg);
                                        meta.*.meta_type = metaType;
                                        switch (metaType) {
                                            .charset => meta.*.charset = @constCast(args[i + 1]),
                                            .property => {
                                                if (meta.property) |_| {
                                                    meta.*.content = @constCast(args[i + 1]);
                                                } else {
                                                    meta.*.property = @constCast(args[i + 1]);
                                                }
                                            },
                                            else => meta.*.content = @constCast(args[i + 1]),
                                        }
                                    },
                                    .Pointer => {},
                                    else => self.fatal(NodeError.invalidArgs, args),
                                }
                            }
                        }
                    },
                    else => self.fatal(NodeError.invalidArgs, args),
                }
            },
            .custom => |*custom| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {
                            inline for (args, 0..) |arg, i| {
                                switch (@typeInfo(@TypeOf(arg))) {
                                    .Pointer => |pointer| {
                                        if (@typeInfo(pointer.child) == .Array) {
                                            if (i < args.len - 1) {
                                                // stringとみなす
                                                custom.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("hoge"));
                                            } else {
                                                // 続くargがなければ非フォーマット文字列
                                                custom.*.template = @constCast(arg);
                                            }
                                        } else if (pointer.child == u8) {
                                            custom.*.template = @constCast(arg);
                                        }
                                    },
                                    .Struct => {
                                        if (@TypeOf(arg) == Node) {
                                            tmp.children.append(arg) catch |e| switch (e) {
                                                else => @panic("failed to append children"),
                                            };
                                        }
                                    },
                                    else => self.fatal(NodeError.invalidArgs, args),
                                }
                            }
                        }
                    },
                    else => |e| {
                        if (e == .Array or e == .Pointer) {
                            // 単なる文字列と仮定
                            custom.*.template = @constCast(args);
                        }
                    },
                }
            },
        }
        return tmp;
    }

    pub fn setClass(self: *const Node, comptime class_name: []const u8) Node {
        var tmp = self.*;
        if (tmp.class) |class| {
            tmp.class = std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ class, @constCast(class_name) }) catch @panic("failed to format class string");
        } else {
            tmp.class = @constCast(class_name);
        }
        return tmp;
    }

    pub fn setId(self: *const Node, comptime id_name: []const u8) Node {
        var tmp = self.*;
        tmp.id = @constCast(id_name);
        return tmp;
    }

    pub fn loadWebAssembly(self: *const Node, filename: []const u8, handler: h.JsHandler) Node {
        var tmp = self.*;
        const loader = .{ .webassembly = h.WebAssembly.init(filename, handler) };
        tmp.loadContents.append(loader) catch |e| {
            std.debug.panic("failed to append loadContents.\n{s}", .{@errorName(e)});
        };
        return tmp;
    }

    pub fn addEventListener(self: *const Node, event: h.Events, js: h.JsWrapper) Node {
        var tmp = self.*;
        tmp.handlers.put(event, js) catch |e| {
            std.debug.panic("{s}: failed to put {any} in event handler.", .{ @errorName(e), event });
        };
        return tmp;
    }

    pub fn addHandler(self: *const Node, eventName: []const u8, handler: JsHandler) Node {
        var tmp = self.*;
        tmp.handlers.put(eventName, handler) catch |e| {
            std.debug.panic("{s}: failed to put {s} in event handler.", .{ @errorName(e), eventName });
        };
        return tmp;
    }

    pub fn addChild(self: *const Node, child: Node) void {
        @constCast(self).children.append(child) catch |e| switch (e) {
            else => @panic("failed to append children"),
        };
    }

    pub fn iterate(self: *const Node, contents: anytype) Node {
        var tmp = self.*;
        inline for (contents) |content| {
            tmp.addIterateChild(content);
        }
        return tmp;
    }

    pub fn addIterateChild(self: *Node, child: Node) void {
        self.children.append(child) catch |e| switch (e) {
            else => @panic("failed to append children"),
        };
    }

    pub fn deinit(self: *Node) void {
        _ = self;
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("Memory leaked");
    }

    const NodeError = error{
        invalidArgs,
    };

    fn fatal(self: *const Node, err: NodeError, args: anytype) noreturn {
        std.log.err("{any}\n{any}\n@{any}\n", .{ err, args, self.elem });
        std.process.exit(1);
    }
};

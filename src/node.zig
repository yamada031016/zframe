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
        .listener = std.AutoHashMap(u64, h.EventListener).init(allocator),
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
    listener: std.AutoHashMap(u64, h.EventListener),
    loadContents: std.ArrayList(Loader),
    class: ?[]u8 = null,
    id: ?[]u8 = null,
    is: ?[]u8 = null,

    pub fn init(self: *const Node, args: anytype) Node {
        var tmp = Node{
            .elem = self.elem,
            .class = self.class,
            .id = self.id,
            .is = self.is,
            .listener = std.AutoHashMap(u64, h.EventListener).init(alloc),
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
                                                // expect []const u8
                                                plane.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("failed to format template string."));
                                            } else {
                                                // expect []const u8 without format specific.
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
                            inline for (s.fields) |field| {
                                if (@hasField(@TypeOf(plane.*), field.name)) {
                                    @field(plane, field.name) = @constCast(@field(args, field.name));
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
                                }
                            }
                        }
                    },
                    else => |e| {
                        if (e == .Array or e == .Pointer) {
                            // expect string
                            plane.*.template = @constCast(args);
                        }
                    },
                }
            },
            .image => |*image| {
                switch (@typeInfo(@TypeOf(args))) {
                    .Struct => |s| {
                        if (s.is_tuple) {} else {
                            inline for (s.fields) |field| {
                                if (@hasField(@TypeOf(image.*), field.name)) {
                                    @field(image, field.name) = @constCast(@field(args, field.name));
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
                            inline for (s.fields) |field| {
                                if (@hasField(@TypeOf(hyperlink.*), field.name)) {
                                    @field(hyperlink, field.name) = @constCast(@field(args, field.name));
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
                            inline for (s.fields) |field| {
                                if (@hasField(@TypeOf(link.*), field.name)) {
                                    @field(link, field.name) = @constCast(@field(args, field.name));
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
                        } else {
                            inline for (s.fields) |field| {
                                if (@hasField(@TypeOf(meta.*), field.name)) {
                                    @field(meta, field.name) = @constCast(@field(args, field.name));
                                } else {
                                    self.fatal(NodeError.invalidArgs, args);
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
                                                custom.*.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("hoge"));
                                            } else {
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
                            custom.*.template = @constCast(args);
                        }
                    },
                }
            },
        }
        return tmp;
    }

    pub fn setClass(self: *const Node, class_name: []const u8) Node {
        var tmp = self.*;
        if (tmp.class) |class| {
            tmp.class = std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ class, @constCast(class_name) }) catch @panic("failed to format class string");
        } else {
            tmp.class = @constCast(class_name);
        }
        return tmp;
    }

    pub fn setId(self: *const Node, id_name: []const u8) Node {
        var tmp = self.*;
        if (tmp.id) |id| {
            tmp.id = std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ id, @constCast(id_name) }) catch @panic("failed to format class string");
        } else {
            tmp.id = @constCast(id_name);
        }
        return tmp;
    }

    pub fn define(self: *const Node, custom_name: []const u8) Node {
        var tmp = self.*;
        tmp.is = @constCast(custom_name);
        return tmp;
    }

    pub fn loadWebAssembly(self: *const Node, filename: []const u8, handler: h.JsHandler) Node {
        var tmp = self.*;
        const loader = h.Loader{ .webassembly = h.WebAssembly.init(filename, handler) };
        tmp.loadContents.append(loader) catch |e| {
            std.debug.panic("failed to append loadContents.\n{s}", .{@errorName(e)});
        };
        return tmp;
    }

    pub fn addEventListener(self: *const Node, listener: h.EventListener) Node {
        var tmp = self.*;
        const randomNumber = generate: {
            while (true) {
                const r = std.crypto.random.int(u64);
                if (!tmp.listener.contains(r)) {
                    break :generate r;
                }
            }
        };
        tmp.listener.put(randomNumber, listener) catch |e| {
            std.debug.panic("{s}: failed to put {any} in event handler.", .{ @errorName(e), listener });
        };
        return tmp.setId(std.fmt.allocPrint(std.heap.page_allocator, "{}", .{randomNumber}) catch unreachable);
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

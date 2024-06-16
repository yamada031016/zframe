const std = @import("std");
const Tag = @import("html.zig").Tag;

pub fn createElement(comptime tagName: Tag) switch (tagName) {
    .p, .heading, .div => Element,
    else => Element,
} {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    _ = allocator;
    return switch (tagName) {
        else => {
            var tmp = [_]*const Element{undefined} ** 10;
            _ = &tmp;
            return .{
                .tag = tagName,
                // .children = std.ArrayList(Element).init(allocator),
            };
        },
    };
}

pub const Element = struct {
    const Self = @This();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    tag: Tag,
    template: ?[]u8 = null,
    // child: ?*const Self = null,
    // children: std.ArrayList(Element),
    children: ?[]Element = null,
    class: ?[]u8 = null,

    // pub fn init(self: *const Self, comptime string: []const u8, comptime args: anytype) Self {
    pub fn init(self: *const Self, args: anytype) Self {
        var tmp = Self{
            .tag = self.tag,
            .class = self.class,
            .children = self.children,
        };

        var child_cnt: u4 = 0;
        var children: [15]Element = undefined;
        inline for (args, 0..) |arg, i| {
            switch (@typeInfo(@TypeOf(arg))) {
                .Pointer => |pointer| {
                    if (@typeInfo(pointer.child) == .Array) {
                        if (i < args.len - 1) {
                            // stringとみなす
                            tmp.template = @constCast(std.fmt.allocPrintZ(alloc, arg, args[i + 1]) catch @panic("hoge"));
                        } else {
                            // 続くargがなければ非フォーマット文字列
                            tmp.template = @constCast(arg);
                            // std.debug.print("{s} arg:{s}\n", .{ self.tag.asText(), arg });
                        }
                    } else if (pointer.child == u8) {
                        tmp.template = @constCast(arg);
                    } else if (@TypeOf(arg.*) == Element) {
                        std.debug.print("len:{}\n", .{child_cnt});
                        children[child_cnt] = (arg.*);
                        std.debug.print("arg:{x}:{s}\n", .{ @intFromPtr(arg), arg.tag.asText() });
                        if (child_cnt <= 9) {
                            child_cnt += 1;
                        } else {
                            @panic("overflow child_cnt");
                        }
                        // tmp.child = (arg);
                        // if (tmp.children.append((arg.*))) {} else |e| {
                        //     switch (e) {
                        //         else => std.debug.print("{s}", .{@errorName(e)}),
                        //     }
                        // }
                        // tmp.child = (&[_]Self{(arg.*)});
                    }
                },
                .Struct => {
                    if (@TypeOf(arg) == Self) {
                        // std.debug.print("args: {any}\n", .{arg});
                        // tmp.child = (&arg);
                        tmp.children.append(@constCast(arg)) catch |e| switch (e) {
                            else => {},
                        };
                    }
                },
                else => {},
            }
        }

        if (child_cnt > 0) {
            // tmp.children = (children[0..child_cnt]);
            tmp.children = children[0..child_cnt];
        }
        return tmp;
    }

    pub fn setClass(self: *const Self, comptime css: []const u8) Self {
        var a: []u8 = undefined;
        a = @constCast(css);
        var tmp = self.*;
        tmp.class = a;
        return tmp;
        // return Self{
        //     .tag = self.tag,
        //     .template = self.template,
        //     .children = self.children,
        //     .class = a,
        // };
    }
};

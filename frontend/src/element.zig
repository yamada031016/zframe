const std = @import("std");
const Tag = @import("html.zig").Tag;

pub fn createElement(tagName: Tag) Element {
    return .{
        .tag = tagName,
    };
}

pub const Element = struct {
    const Self = @This();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    tag: Tag,
    template: ?[]u8 = null,
    // child: ?[]*Self = null,
    child: ?*const Self = null,
    class: []u8 = "",

    // pub fn init(self: *const Self, comptime string: []const u8, comptime args: anytype) Self {
    pub fn init(self: *const Self, args: anytype) Self {
        var tmp = Self{
            .tag = self.tag,
            .class = self.class,
        };
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
                        tmp.child = (arg);
                        // std.debug.print("child!", .{});
                        // tmp.child = (&[_]Self{(arg.*)});
                    }
                },
                .Struct => {
                    if (@TypeOf(arg) == Self) {
                        // std.debug.print("args: {any}\n", .{arg});
                        tmp.child = (&arg);
                    }
                },
                else => {},
            }
        }
        return tmp;
    }

    pub fn setClass(self: *const Self, comptime css: []const u8) Self {
        var a: []u8 = undefined;
        a = @constCast(css);
        return Self{
            .tag = self.tag,
            .template = self.template,
            .child = self.child,
            .class = a,
        };
    }
};

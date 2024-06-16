const std = @import("std");

pub const Tag = enum {
    span,
    div,
    heading,
    p,

    pub fn asText(tag: *const Tag) []const u8 {
        // std.debug.print("tag text: {any}\n", .{tag});
        return switch (tag.*) {
            .div => "div",
            .heading => "h1",
            .p => "p",
            .span => "span",
        };
    }
};

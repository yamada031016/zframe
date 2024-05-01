const std = @import("std");
const html = @import("html.zig");

pub fn main() !void {
    const div = html.createElement(.div);
    const h = html.createElement(.heading);
    try html.render("#app", .{
        div.init(.{ "Hello {s}", .{"Div!"} }),
        div.init(.{
            h.init(.{"Hello"}),
        }).setClass("white"),
        // h.init(.{ "Hello {s}", .{"heading!"} }),
    });
}

const std = @import("std");
const zframe = @import("zframe");

// add page rendering way later
pub fn main() !void {
    // Layout(.{page}) and so on.
    try zframe.render.render("index.zig", @import("pages/index.zig").index());
}

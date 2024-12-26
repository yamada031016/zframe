const std = @import("std");
const zframe = @import("zframe");

pub fn main() !void {
    try zframe.render.render("src/pages/index.zig", @import("pages/index.zig").index());
}

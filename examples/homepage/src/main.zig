const std = @import("std");
const zframe = @import("zframe");
const c = @import("components");

pub fn main() !void {
    try zframe.render.config(c.layout.Layout);
    try zframe.render.render("src/pages/index.zig", @import("pages/index.zig").index());
    try zframe.render.render("src/pages/about.zig", @import("pages/about.zig").about());
}

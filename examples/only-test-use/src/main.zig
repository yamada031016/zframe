const std = @import("std");
const Layout = @import("components").layout.Layout;
const zframe = @import("zframe");

// add page rendering way later
pub fn main() !void {
    try zframe.render.config(Layout);
}

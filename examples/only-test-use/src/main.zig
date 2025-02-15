const std = @import("std");
const Layout = @import("components").layout.Layout;
const zframe = @import("zframe");

pub fn main() !void {
    try zframe.render.config(Layout);
    try zframe.render.render("src/pages/index.zig", @import("pages/index.zig").index());
    try zframe.render.render("src/pages/about.zig", @import("pages/about.zig").about());
    try zframe.render.mdToHtml("src/pages/Document.md");
}

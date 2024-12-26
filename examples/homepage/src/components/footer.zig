const std = @import("std");
const zframe = @import("zframe");
const node = zframe.node;
const Node = node.Node;

pub fn Footer() Node {
    const div = node.createNode(.div);
    const footer = node.createNode(.footer);

    const epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
    const year = epoch.getEpochDay().calculateYearDay();

    const copyright = div.init(.{ "SecHack365 &copy;{}", .{year.year} });

    return footer.setClass("border-t border-300-cyan pt-4").init(.{
        copyright.setClass("pb-2 text-sm text-center"),
    });
}

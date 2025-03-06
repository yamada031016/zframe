const std = @import("std");
const zframe = @import("zframe");
const node = zframe.node;
const Node = node.Node;

pub fn Footer() Node {
    const div = node.createNode(.div);
    const footer = node.createNode(.footer);

    const epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
    const year = epoch.getEpochDay().calculateYearDay();

    const copyright = div.init(.{ "&copy;{} zframe", .{year.year} });

    return footer.setClass("py-8 text-center text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-800").init(.{
        copyright,
    });
}

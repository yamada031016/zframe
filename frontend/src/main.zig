const std = @import("std");
const render = @import("render.zig").render;
const elem = @import("element.zig");
const Element = elem.Element;
const node = @import("node.zig");
const Node = node.Node;

pub fn main() !void {
    const div = node.createNode(.div);
    const p = node.createNode(.p);
    const epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
    const year = epoch.getEpochDay().calculateYearDay();

    const copyright = p.init(.{ "&copy;{}", .{year.year} });

    try render("#app", .{
        Header("zFrame -- Zig Web Backend Framework"),
        assert("zFrame is a temporary name."),
        assert("This is still under development."),
        README(),

        div.setClass("text-center border-b border-300-cyan").init(.{
            div.setClass("pb-2").init(.{
                copyright.setClass("text-sm"),
            }),
        }),
    });
}

fn Header(title: []const u8) Node {
    const div = node.createNode(.div);
    const h = node.createNode(.heading);
    return div.setClass("text-center my-10").init(.{
        h.init(.{title}).setClass("text-4xl text-indigo-700 font-bold"),
    });
}

inline fn assert(assert_text: []const u8) Node {
    const div = node.createNode(.div);
    const p = node.createNode(.p);
    return div.setClass("mx-auto text-center my-10 bg-indigo-200 w-1/3 border rounded-2xl border-indigo-300").init(.{
        p.init(.{"[!]\t" ++ assert_text}).setClass("text-lg px-1 py-2 text-gray-600 font-black"),
    });
}

fn README() Node {
    const div = node.createNode(.div);
    const p = node.createNode(.p);

    return div.setClass("text-lg text-gray-700 font-semibold text-center my-10").init(.{
        p.init(.{" The Web framework for mainting robust, optimal and reusable by Zig language."}),
        p.init(.{"This is developed at SecHack365 in 2024."}),
    });
}

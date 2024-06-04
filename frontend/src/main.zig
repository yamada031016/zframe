const std = @import("std");
const render = @import("render.zig").render;
const elem = @import("element.zig");
const Element = elem.Element;

const div = elem.createElement(.div);
const h = elem.createElement(.heading);
const p = elem.createElement(.p);

pub fn main() !void {
    const epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
    const year = epoch.getEpochDay().calculateYearDay();

    const copyright = p.init(.{ "&copy;{}", .{year.year} });

    try render("#app", .{
        comptime Header("zFrame -- Zig Web Backend Framework"),
        assert("zFrame is a temporary name."),
        assert("This is still under development."),
        comptime README(),

        div.setClass("text-center border-b border-300-cyan").init(.{
            &div.setClass("pb-2").init(.{
                &copyright.setClass("text-sm"),
            }),
        }),
    });
}

fn Header(title: []const u8) Element {
    return div.setClass("text-center my-10").init(.{
        &h.init(.{title}).setClass("text-4xl text-indigo-700 font-bold"),
    });
}

inline fn assert(assert_text: []const u8) Element {
    return div.setClass("mx-auto text-center my-10 bg-indigo-200 w-1/3 border rounded-2xl border-indigo-300").init(.{
        &p.init(.{"[!]\t" ++ assert_text}).setClass("text-lg px-1 py-2 text-gray-600 font-black"),
    });
}

fn README() Element {
    return div.setClass("text-center my-10").init(.{
        &p.setClass("text-lg text-gray-700 font-semibold").init(.{
            \\ The Web framework for mainting robust, optimal and reusable by Zig language.</p>
            \\ <p class="text-lg text-gray-700 font-semibold">This is developed at SecHack365 in 2024.</p>
            \\ <p class="text-lg text-gray-700 font-semibold">GitHub Repository is here: https://github.com/yamada031016/zframe
        }),
    });
}

const zframe = @import("zframe");
const node = zframe.node;
const Node = node.Node;

const nav_list = [_][2][]const u8{
    [_][]const u8{ "/", "Zframe" },
    [_][]const u8{ "/about", "About us" },
    [_][]const u8{ "/Documentation", "Documentation" },
    [_][]const u8{ "/Downloads", "Downloads" },
    [_][]const u8{ "/about/contact", "Contact" },
};

pub fn Header() Node {
    const header = node.createNode(.header);
    const nav = node.createNode(.nav).init(.{});
    const a = node.createNode(.a);

    return header.setClass("").init(.{
        inline for (nav_list) |n| {
            nav.addChild(
                a.init(.{ n[0], .{}, n[1] }).setClass(
                    \\ hover:text-[#f7b125] py-6 text-[#25332a]
                    \\ first:bg-[#feb534] first:text-white first:font-extrabold first:px-10 first:hover:text-gray-200
                ),
            );
        },
        nav.setClass("text-lg flex justify-around"),
    });
}

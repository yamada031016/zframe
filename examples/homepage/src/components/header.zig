const zframe = @import("zframe");
const c = @import("components");
const node = zframe.node;
const Node = node.Node;

const nav_list = [_][2][]const u8{
    [_][]const u8{ "/about", "About us" },
    [_][]const u8{ "/Docs", "Docs" },
    [_][]const u8{ "https://github.com/yamada031016/zframe", "GitHub" },
};

pub fn Header() Node {
    const header = node.createNode(.header);
    const nav = node.createNode(.nav).init(.{});
    const h1 = node.createNode(.h1);
    const div = node.createNode(.div);
    const Link = c.Link.Link("https://yamada031016.github.io/zframe/");

    return header.setClass("bg-opacity-80 backdrop-blur-lg bg-white shadow-lg dark:bg-gray-800").init(.{
        inline for (nav_list) |n| {
            nav.addChild(
                Link(.{
                    .href = n[0],
                    .template = n[1],
                }).setClass("hover:text-black dark:hover:text-white transition"),
            );
        },
        div.setClass("flex justify-between items-center py-4 px-8").init(.{
            h1
                .setClass("text-3xl font-[Orbitron] font-bold bg-gradient-to-r from-pink-500 via-red-500 to-yellow-500 bg-clip-text text-transparent font-orbitron")
                .init(.{Link(.{ .href = "/", .template = "zFrame" })}),
            nav.setClass("flex gap-6 text-gray-600 dark:text-gray-300"),
        }),
    });
}

const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn index() node.Node {
    const h1 = node.createNode(.h1);
    const h2 = node.createNode(.h2);
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    const a = node.createNode(.a);

    return div.setClass("text-[#25332a] ").init(.{
        h1.init("zFrame"),
        p.init("Modern Web Frontend Framework with WebAssembly"),
        p.init("you can use and integrate WebAssembly easily"),

        h2.init("Let's create your website in Zig lang!"),

        h2.init("Some example projects are here!"),
        a.init(.{ .href = "https://github.com/yamada031016/zframe", .template = "zframe project repository" }),
    });
}

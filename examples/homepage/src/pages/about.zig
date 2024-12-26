const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn about() node.Node {
    const h1 = node.createNode(.h1);
    const p = node.createNode(.p);
    const div = node.createNode(.div);

    return div.init(.{
        Head("zframe - about us", .{}),
        h1.init("About").setClass("text"),
        p.setClass("hoge").init("zframe is a opensource and secure Web Frontend Framework written in Zig."),
    });
}

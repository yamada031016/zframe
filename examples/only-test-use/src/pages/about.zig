const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

fn about() node.Node {
    const h1 = node.createNode(.h1);
    const div = node.createNode(.div);

    return div.setClass("").init(.{
        Head("zframe - Zig Web Frontend Framework", .{}),
        h1.init("about"),
    });
}

pub fn main() !void {
    try z.render.render(@src().file, about());
}

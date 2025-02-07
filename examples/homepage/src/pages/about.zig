const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn about() node.Node {
    const p = node.createNode(.p);
    const div = node.createNode(.div);

    return div.init(.{
        Head("about zframe", .{}),
        p.init("under development"),
        p.init("Hold on a second!"),
    });
}

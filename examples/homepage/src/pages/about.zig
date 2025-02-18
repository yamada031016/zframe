const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn about() node.Node {
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    const title = node.createNode(.title);

    return div.init(.{
        // Head("About zframe", .{}),
        title.init("About zframe"),
        p.init("under development"),
        p.init("Hold on a second!"),
    });
}

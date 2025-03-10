const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn about() node.Node {
    const p = node.createNode(.p);
    const title = node.createNode(.title);
    const div = node.createNode(.div);

    return div.init(.{
        title.init("About zframe"),
        p
            .init("under development")
            .setClass("text-xl"),
        p.init("Hold on a second!"),
    });
}

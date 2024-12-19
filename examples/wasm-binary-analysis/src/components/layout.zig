const z = @import("zframe");
const node = z.node;
const c = @import("components");

pub fn Layout(page: node.Node) node.Node {
    const div = node.createNode(.div);
    const html = node.createNode(.html);
    return html.init(.{
        div.setClass("").init(.{
            page,
        }),
    });
}

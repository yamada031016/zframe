const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

fn index() node.Node {
    const p = node.createNode(.p);
    const clickHandler = z.handler.EventListener{
        .target = .click,
        .js = .{
            .javascript = .{
                .filename = "alert.js",
                .func = "test",
            },
        },
        .options = null,
    };

    return p.init("Hello Praia!").addEventListener(clickHandler);
}

pub fn main() !void {
    try z.render.render(@src().file, index());
}

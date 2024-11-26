const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;
const h = z.handler;
const WebAssembly = z.handler.WebAssembly;

fn index() node.Node {
    const h1 = node.createNode(.h1);
    const p = node.createNode(.p);
    const div = node.createNode(.div);

    return div.setClass("").init(.{
        Head("zframe - Zig Web Frontend Framework", .{}),
        h1.init("ONLY TEST USE"),
        node.createNode(.h2).init("h2"),
        node.createNode(.h3).init("h3"),
        node.createNode(.h4).init("h4"),
        node.createNode(.h5).init("h5"),
        node.createNode(.h6).init("h6"),
        p.init("hoge"),
        node.createNode(.a).init(.{ "/", .{}, "index page" }),
        node.createNode(.a).init(.{ .href = "/about", .template = "about page" }),
    });
}

pub fn main() !void {
    const handler = z.handler.JsHandler{
        .then = .{
            .filename = "alert.js",
            .func = "test",
        },
    };
    try z.render.render(@src().file, index().loadWebAssembly("one.wasm", handler));
}

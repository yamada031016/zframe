const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

fn index() node.Node {
    const p = node.createNode(.p);
    const handler = z.handler.JsHandler{
        .then = .{
            .filename = "convert.js",
            .func = "wasm",
        },
    };
    const loader = z.handler.Loader{ .webassembly = z.handler.WebAssembly.init("hash.wasm", handler) };
    const clickHandler = z.handler.EventListener{
        .target = .click,
        .content = loader,
        .options = null,
    };

    return node.createNode(.div).init(.{
        p.init("Analyze WebAssembly!").setClass("text-4xl"),
        node.createNode(.form).init(.{
            node.createNode(.input).init(.{
                .type = .file,
                .accept = ".wasm",
            }).setId("input"),
            node.createNode(.div).init("encrypt").addEventListener(clickHandler),
        }),
        p.init("result here").setClass("text-sm").setId("result"),
    });
}

pub fn main() !void {
    try z.render.render(@src().file, index());
}

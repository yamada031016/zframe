const z = @import("zframe");
const c = @import("components");
const node = z.node;

fn index() node.Node {
    const div = node.createNode(.div);

    return div.init(.{
        resultPreview(),
    });
}

fn resultPreview() node.Node {
    const custom = node.createNode(.custom);
    const result_preview = custom.define("result-preview");
    // const div = node.createNode(.div);
    const h2 = node.createNode(.h2);
    const handler = z.handler.JsHandler{
        .then = .{
            .filename = "alert.js",
            .func = "test",
        },
    };
    const loader = z.handler.Loader{ .webassembly = z.handler.WebAssembly.init("one.wasm", handler) };
    const clickHandler = z.handler.EventListener{
        .target = .click,
        .content = loader,
        .options = null,
    };
    // return div.init(.{
    //     h2.setClass("text-xl text-red-500").init("Test"),
    // }).addEventListener(clickHandler);
    return result_preview.init(.{
        h2.setClass("text-xl text-red-500").init("Test"),
    }).addEventListener(clickHandler);
}

pub fn main() !void {
    try z.render.render(@src().file, index());
}

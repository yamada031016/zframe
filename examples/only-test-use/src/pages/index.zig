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
        node.createNode(.a).init(.{
            .href = "/about",
            .template = "about page",
            .target = .blank,
            .download = "hoge",
            .rel = .help,
            .hreflang = "ja",
            .ping = "/",
            .referrerpolicy = .noReferrer,
            .mimeType = "text/html",
            .attributionsrc = "/",
        }),
        node.createNode(.img).init(.{ .src = "", .alt = "hoge" }),
        node.createNode(.link).init(.{
            .type = .style,
            .crossorigin = .anonymous,
        }),
        node.createNode(.cite).init("hoge"),
        node.createNode(.p).init(.{
            .template = "edit here!",
            .accesskey = "i",
            .contenteditable = true,
            .dir = .leftToRight,
            .draggable = true,
            // .hidden = false,
            .itemprop = "edit",
            .lang = "ja",
            .role = "alert",
            .slot = "hoge",
            .spellcheck = true,
            .style = "text:red;",
            .title = "title",
            .translate = true,
        }),
        node.createNode(.table).init(.{
            node.createNode(.caption).init("sample table"),
            node.createNode(.thead).init(.{
                node.createNode(.tr).init(.{
                    node.createNode(.th).init("Items"),
                    node.createNode(.th).init("Expenditure"),
                }),
            }),
            node.createNode(.tbody).init(.{
                node.createNode(.tr).init(.{
                    node.createNode(.th).init("Donuts"),
                    node.createNode(.td).init("3,000"),
                }),
                node.createNode(.tr).init(.{
                    node.createNode(.th).init("Stationery"),
                    node.createNode(.td).init("18,000"),
                }),
            }),
            node.createNode(.tfoot).init(.{
                node.createNode(.tr).init(.{
                    node.createNode(.th).init(.{
                        .template = "Totals",
                        // .scope = "row",
                    }),
                    node.createNode(.td).init("21,000"),
                }),
            }),
        }),
        node.createNode(.form).init(.{
            node.createNode(.div).init(.{
                node.createNode(.label).init(.{
                    .template = "Enter your name",
                    // .forName="name"
                }),
                node.createNode(.input).init(.{
                    .type = .text,
                    .name = "name",
                    .required = true,
                }),
            }),
            node.createNode(.input).init(.{
                .type = .submit,
                .value = "subscribe!",
            }),
        }),
    });
}

pub fn main() !void {
    // const handler = z.handler.JsHandler{
    //     .then = .{
    //         .filename = "alert.js",
    //         .func = "test",
    //     },
    // };
    // try z.render.render(@src().file, index().loadWebAssembly("one.wasm", handler));
    try z.render.render(@src().file, index());
}

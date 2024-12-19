const z = @import("zframe");
const c = @import("components");
const w = @import("api");
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
        wasmAnalysisTable(&.{}),
    });
}

fn wasmAnalysisTable(type_sections: []w.TypeSecInfo) node.Node {
    _ = type_sections;
    const custom = node.createNode(.custom);
    const analysis_table = custom.define("analysis-table");
    // const tbody = node.createNode(.tbody).init(.{});
    return analysis_table.init(.{
        node.createNode(.table).init(.{
            node.createNode(.caption).init("Analysis Result"),
            node.createNode(.thead).init(.{
                node.createNode(.tr).init(.{
                    node.createNode(.th).init(.{ .template = "ID", .scope = .col }),
                    node.createNode(.th).init(.{ .template = "params", .scope = .col }),
                    node.createNode(.th).init(.{ .template = "results", .scope = .col }),
                }),
            }),
            // for (type_sections, 0..) |type_section, i|
            // {
            //     tbody.addChild(
            //         node.createNode(.tr).init(.{
            //             node.createNode(.td).init(i),
            //             node.createNode(.td).init(.{type_section.args_type}),
            //             node.createNode(.td).init(.{type_section.result_type}),
            //         }),
            //     );
            // },
            // tbody,
            node.createNode(.tbody).init(.{
                node.createNode(.raw).init(
                    \\ ${this._data.map((t, i) => `
                    \\ <tr>
                    \\ <td>${i}</td>
                    \\ <td>${t.args_type}</td>
                    \\ <td>${t.result_type}</td>
                    \\ </tr>
                    \\ `).join("")}
                ),
            }),
        }),
    });
}

pub fn main() !void {
    try z.render.render(@src().file, index());
}

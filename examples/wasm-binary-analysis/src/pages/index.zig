const z = @import("zframe");
const c = @import("components");
const w = @import("api");
const Head = c.head.Head;
const node = z.node;

pub fn index() node.Node {
    const h1 = node.createNode(.h1);
    const handler = z.handler.JsHandler{
        .then = .{
            .filename = "convert.js",
            .func = "wasm",
        },
    };
    const loader = z.handler.Loader{ .webassembly = z.handler.WebAssembly.init("hash.wasm", handler) };
    const clickHandler = z.handler.EventListener{
        .target = .change,
        .content = loader,
        .options = null,
    };

    return node.createNode(.div).init(.{
        c.head.Head("Wasm Binary Analyzer", .{}),
        node.createNode(.div).setClass("bg-gray-900 text-white font-sans").init(.{
            node.createNode(.div).setClass("min-h-screen flex flex-col items-center py-8").init(.{
                h1.init("Analyze WebAssembly!").setClass("text-3xl font-bold text-purple-400 mb-6"),
                node.createNode(.div).setClass("w-full max-w-4xl px-4").init(.{
                    node.createNode(.form).init(.{
                        // <label for="wasmFileInput" class="block text-lg font-medium text-purple-400 mb-2">Upload Wasm File</label>
                        node.createNode(.input)
                            .init(.{ .type = .file, .accept = ".wasm" })
                            .setId("input")
                            .setClass("block w-full text-gray-300 bg-gray-800 border border-gray-600 rounded-md px-3 py-2 cursor-pointer focus:outline-none focus:ring-2 focus:ring-purple-400 focus:border-purple-400 transition-all")
                            .addEventListener(clickHandler),
                    }),
                }),
                wasmAnalysisTable(&.{}),
            }),
        }),
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

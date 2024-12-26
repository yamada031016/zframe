const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn index() node.Node {
    const h1 = node.createNode(.h1);
    const h2 = node.createNode(.h2);
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    const a = node.createNode(.a);
    const code = node.createNode(.code);

    return div.setClass("text-black ").init(.{
        Head("zframe - Zig Web Frontend Framework", .{}),
        div.setClass("text-center mt-32").init(.{
            h1.init(.{"zframe -- Web Frontend Framework"}).setClass("text-5xl text-[#2d94a0] font-black"),
            p.init(.{
                \\ Utilize Wasm easily, without any configure and technics.<br>
                \\ zframe enable you to integrate Wasm and your Website.
            }).setClass("text-xl pt-6"),
        }),
        div.setClass("flex justify-center gap-8 pt-24").init(.{
            a.setClass("py-3 px-6 text-lg font-bold text-white bg-[#feb534] border").init(.{ "Documentation", .{}, "Get Started" }),
            a.setClass("py-3 px-6 text-lg font-bold border border-gray-200").init(.{ "Documentation", .{}, "Learn Zframe" }),
        }),
        a.setClass("text-center block mt-8 text-gray-700 font-light").init(.{"https://github.com/yamada031016/zframe"}),
        div.setClass("mt-40 bg-[#2d94a0] px-28 py-20").init(.{ div.setClass("flex justify-center items-end").init(.{
            h2.setClass("text-3xl font-extrabold text-[#d0db7b]").init(.{"What's in zframe?"}),
            p.setClass("text-lg pl-4 text-white").init(.{"A flexible, fast, robust framework written in Zig"}),
        }), div.setClass("pt-12").init(.{
            cardContainer(),
        }) }),
        div.setClass("mx-auto w-4/5").init(.{
            h2.setClass("text-3xl font-bold text-center text-[#feb534]").init("Expressive components system"),
            div.setClass("bg-[#3b5564] text-white p-4 border rounded-lg").init(.{
                code.init(.{
                    p.init("const z = @import(\"zframe\");"),
                    p.init("const c = @import(\"components\");"),
                    p.init("const Head = c.head.Head;"),
                    p.init("const node = z.node;"),
                    p.init("const Layout = @import(\"components\").layout.Layout;"),
                    p.init("fn about() node.Node {"),
                    p.setClass("ml-7").init("const h1 = node.createNode(.h1);"),
                    p.setClass("ml-7").init("const p = node.createNode(.p);"),
                    p.setClass("ml-7").init("const div = node.createNode(.div);"),
                    p.setClass("ml-7").init("return div.init(.{"),
                    p.setClass("ml-14").init("h1.init(\"About\").setClass(\"text\"),"),
                    p.setClass("ml-14").init("p.setClass(\"hoge\").init(\"zframe is a opensource and secure Web Frontend Framework written in Zig.\"),"),
                    p.setClass("ml-7").init("});"),
                    p.init("}"),
                    p.init("pub fn main() !void {"),
                    p.setClass("ml-7").init("try z.render.render(@src().file, Layout(about()));"),
                    p.init("}"),
                }),
            }),
        }),
        div.setClass("mx-auto w-4/5").init(.{
            h2.setClass("text-3xl font-bold text-center text-[#feb534]").init("inline for-loop expression"),
            div.setClass("bg-[#3b5564] text-white p-4 border rounded-lg").init(.{
                code.init(.{
                    p.init("const div = node.createNode(.div).init(.{});"),
                    p.init("const empty = node.createNode(.empty);"),
                    p.init("const feature_cards = [_][2][]const u8{"),
                    p.setClass("pl-7").init("[_][]const u8{ \"Unique Components System\", \"construct DOM by method-chain, develop securely by its immutance\" },"),
                    p.setClass("pl-7").init("[_][]const u8{ \"Web Components Support\", \"You can use Web standard technology, especially shadow DOM is useful for styling separately\" },"),
                    p.setClass("pl-7").init("[_][]const u8{ \"Integrated Web Assembly\", \"No setup is needed. All you need to do take advantage of Wasm is to write the Zig code.\" },"),
                    p.init("};"),
                    p.init("return empty.init(.{"),
                    p.setClass("pl-7").init("inline for (feature_cards) |f| {"),
                    p.setClass("pl-14").init("div.addChild(card(f[0], f[1]));"),
                    p.setClass("pl-7").init("},"),
                    p.setClass("pl-7").init("div.setClass(\"grid grid-cols-3 gap-5\"),"),
                    p.init("});"),
                }),
            }),
        }),
        div.setClass("mx-auto w-4/5").init(.{
            h2.setClass("text-3xl font-bold text-center text-[#feb534]").init("WebAssembly integration"),
            div.setClass("bg-[#3b5564] text-white p-4 border rounded-lg").init(.{
                code.init(.{
                    p.init("const handler = Handler.init("),
                    p.setClass("ml-7").init(".webassembly,"),
                    p.setClass("ml-7").init(".{"),
                    p.setClass("ml-14").init(".filename = \"one.wasm\","),
                    p.setClass("ml-14").init(".then = .{"),
                    p.setClass("ml-20").init(".filename = \"alert.js\","),
                    p.setClass("ml-20").init(".func = \"test\","),
                    p.setClass("ml-14").init("},"),
                    p.setClass("ml-7").init("},"),
                    p.init(");"),
                    p.init("try z.render.render(@src().file, index().addHandler(\"webassembly\", handler));"),
                }),
            }),
        }),
    });
}

fn cardContainer() node.Node {
    const div = node.createNode(.div).init(.{});
    const empty = node.createNode(.empty);

    const feature_cards = [_][2][]const u8{
        [_][]const u8{ "Built-in Optimizations", "Automatic Image, Font and Wasm Optimizations are all built-in" },
        [_][]const u8{ "Tailwind CSS Support", "Automatic Image, Font and Wasm Optimizations are all built-in" },
        [_][]const u8{ "Integrated Web Assembly", "Automatic Image, Font and Wasm Optimizations are all built-in" },
        [_][]const u8{ "Built-in Web Server", "Automatic Image, Font and Wasm Optimizations are all built-in" },
        [_][]const u8{ "File System Based Routing", "Automatic Image, Font and Wasm Optimizations are all built-in" },
        [_][]const u8{ "Useful Dev Utils", "Automatic Image, Font and Wasm Optimizations are all built-in" },
    };

    return empty.init(.{
        inline for (feature_cards) |f| {
            div.addChild(card(f[0], f[1]));
        },
        div.setClass("grid grid-cols-3 gap-5"),
    });
}

fn card(title: []const u8, description: []const u8) node.Node {
    const p = node.createNode(.p);
    const div = node.createNode(.div);

    return div.setClass("p-4 border border-1 rounded-xl border-gray-200").init(.{
        p.setClass("text-xl font-bold w-4/5").init(.{title}),
        p.init(.{description}),
    });
}

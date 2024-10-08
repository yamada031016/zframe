const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

fn index() node.Node {
    const h1 = node.createNode(.h1);
    const h2 = node.createNode(.h2);
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    const a = node.createNode(.a);
    // const img = node.createNode(.img);

    return div.setClass("text-[#25332a] ").init(.{
        Head("zframe - Zig Web Frontend Framework", .{}),
        // img.init(.{.src="hoge", .alt="Test image", .width=100, .height=200}),
        div.setClass("text-center mt-32").init(.{
            h1.init(.{"zframe -- Web Frontend Framework"}).setClass("text-5xl text-[#F0544F] font-black"),
            p.init(.{
                \\ Utilize Wasm easily, without any configure and technics.<br>
                \\ zframe enable you to integrate Wasm and your Website.
            }).setClass("text-xl pt-6"),
        }),
        div.setClass("flex justify-center gap-8 pt-24").init(.{
            a.setClass("py-3 px-6 text-lg font-bold text-white bg-[#F0544F] border").init(.{ "Documentation", .{}, "Get Started" }),
            a.setClass("py-3 px-6 text-lg font-bold border border-gray-200").init(.{ "Documentation", .{}, "Learn zframe" }),
        }),
        a.setClass("text-center block mt-8 text-gray-700 font-light").init(.{"https://github.com/yamada031016/zframe"}),
        div.setClass("mt-40 bg-[#F0544F] px-28 py-20").init(.{ div.setClass("flex justify-center items-end").init(.{
            h2.setClass("text-3xl font-extrabold").init(.{"What's in zframe?"}),
            p.setClass("text-lg pl-4").init(.{"A flexible, fast, robust framework written in Zig"}),
        }), div.setClass("pt-12").init(.{
            cardContainer(),
        }) }),
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

const Layout = @import("components").layout.Layout;
pub fn main() !void {
    try z.render.render(@src(), Layout(index()));
}

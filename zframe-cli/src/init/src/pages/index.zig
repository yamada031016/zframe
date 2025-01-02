const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn index() node.Node {
    const h1 = node.createNode(.h1);
    const p = node.createNode(.p);
    const main = node.createNode(.main);
    const a = node.createNode(.a);
    const section = node.createNode(.section);
    const span = node.createNode(.span);

    return main.setClass("bg-gradient-to-br from-gray-900 via-gray-800 to-gray-700 text-white min-h-screen flex flex-col").init(.{
        section.setClass("flex flex-col items-center justify-center text-center flex-grow px-4 py-20 space-y-8").init(.{ h1.setClass("text-6xl font-extrabold text-[#4fd1c5] drop-shadow-md").init("Build the Future with zFrame"), p.setClass("text-lg text-gray-300 max-w-2xl").init(.{
            span.init("Experience a modern web frontend framework powered by "),
            span.setClass("text-[#63b3ed] font-semibold").init("WebAssembly"),
            span.init("Create blazing-fast, scalable, and cross-platform web applications effortlessly."),
        }), a.setClass("px-6 py-3 bg-[#3182ce] text-white font-semibold rounded-lg shadow-lg hover:bg-[#2b6cb0] hover:shadow-2xl transition-all").init(.{
            .href = "https://github.com/yamada031016/zframe",
            .template = "Explore zFrame on GitHub",
        }) }),
    });
}

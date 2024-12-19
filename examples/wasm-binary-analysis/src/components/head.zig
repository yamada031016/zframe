const z = @import("zframe");
const node = z.node;

pub fn Head(page_name: []const u8, contents: anytype) node.Node {
    const raw = node.createNode(.raw);
    const head = node.createNode(.head);
    const title = node.createNode(.title);
    const meta = node.createNode(.meta);

    const empty = node.createNode(.empty).init(.{});

    return head.init(.{
        title.init(.{page_name}),
        meta.init(.{ .description, "zFrame is Zig Web Frontend Framework." }),
        meta.init(.{ .charset, "utf-8" }),
        raw.init(.{
            \\<script src="https://cdn.tailwindcss.com"></script>
            // \\<script type="module">const env = { memory: new WebAssembly.Memory({initial: 2, maximum: 2}),};var memory = env.memory; WebAssembly.instantiateStreaming( fetch("monitor.wasm"),{env}).then(obj => {if(obj.instance.exports.monitor()) {}});</script>
        }),
        empty.iterate(contents),
    });
}

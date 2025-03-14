const z = @import("zframe");
const node = z.node;

pub fn Head(page_name: []const u8, contents: anytype) node.Node {
    const head = node.createNode(.head);
    const title = node.createNode(.title);
    const meta = node.createNode(.meta);

    const empty = node.createNode(.empty).init(.{});

    return head.init(.{
        title.init(.{page_name}),
        meta.init(.{ .description, "zFrame is Zig Web Frontend Framework." }),
        meta.init(.{ .charset, "utf-8" }),
        node.createNode(.raw).init(.{
            \\<script src="https://cdn.tailwindcss.com"></script>
        }),
        empty.iterate(contents),
    });
}

const z = @import("zframe");
const node = z.node;

pub fn Head() node.Node {
    const raw = node.createNode(.raw);
    const head = node.createNode(.head);
    // const title = node.createNode(.title);
    const meta = node.createNode(.meta);
    const link = node.createNode(.link);

    // const empty = node.createNode(.empty).init(.{});

    return head.init(.{
        // title.init(.{page_name}),
        meta.init(.{ .description, "zFrame is Zig Web Frontend Framework." }),
        meta.init(.{ .charset, "utf-8" }),
        meta.init(.{ .viewport, "width=device-width, initial-scale=1.0" }),
        raw.init(.{
            \\ <html>
            \\ <head>
            \\<script src="https://cdn.tailwindcss.com"></script>
            \\ <link rel="preload" href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&display=swap" as="style"
            \\ onload="this.onload=null;this.rel='stylesheet'">
        }),
        link.init(.{
            .rel = "stylesheet",
            .href = "https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&display=swap",
            .as = "style",
        }),
        // empty.iterate(contents),
    });
}

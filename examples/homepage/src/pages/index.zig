const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;

pub fn index() node.Node {
    const main = node.createNode(.main);

    return main.init(.{
        Head("zframe", .{}),
        HeroSection(),
        FeatureSection(),
        RoadMapSection(),
        FAQ(),
        codeline("Expressive components system",
            \\const z = @import("zframe")
            \\const c = @import("components");
            \\const Head = c.head.Head;
            \\const node = z.node;
            \\const Layout = @import("components").layout.Layout;
            \\
            \\fn about() node.Node {
            \\  const h1 = node.createNode(.h1);
            \\  const p = node.createNode(.p);
            \\  const div = node.createNode(.div);
            \\
            \\  return div.init(.{
            \\      h1.init("About").setClass("text"),
            \\      p.setClass("hoge")
            \\       .init("zframe is a opensource and secure Web Frontend Framework written in Zig."),
            \\  });
            \\}
        ),
        codeline("WebAssembly integration",
            \\ const handler = Handler.init(
            \\  .webassembly,
            \\  .{
            \\      .filename = "one.wasm",
            \\      .then = .{
            \\          .filename = "alert.js",
            \\          .func = "test",
            \\      },
            \\  },
            \\);
            \\
            \\ try z.render.render(@src().file, index().addHandler("webassembly", handler));
        ),
    });
}

fn HeroSection() node.Node {
    const h2 = node.createNode(.h2);
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    const span = node.createNode(.span);
    const section = node.createNode(.section);
    const a = node.createNode(.a);

    return section.setClass("text-center py-16 bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800").init(.{
        h2.setClass("font-[Orbitron] text-6xl font-extrabold text-gray-900 dark:text-gray-200").setId("hero-title").init(.{
            "Welcome to ",
            span.setClass("font-[Orbitron] text-9xl bg-gradient-to-r from-pink-500 via-red-500 to-yellow-500 bg-clip-text text-transparent").init("zFrame"),
        }),
        p.setClass("mt-4 text-xl text-gray-600 dark:text-gray-400").init("The framework that transcends boundaries."),
        div.setClass("flex justify-center gap-20 mt-12").init(.{
            a.setClass("mt-8 inline-block py-3 px-6 bg-pink-500 text-white font-bold rounded shadow-lg hover:bg-pink-600 dark:bg-pink-700 dark:hover:bg-pink-600 transition").init(.{
                .target = .blank,
                .href = "https://github.com/yamada031016/zframe/blob/master/docs/tutorial.md",
                .template = "Get Started",
            }),
            a.setClass("mt-8 inline-block py-3 px-6 bg-pink-500 text-white font-bold rounded shadow-lg hover:bg-pink-600 dark:bg-pink-700 dark:hover:bg-pink-600 transition").init(.{
                .target = .blank,
                .href = "about",
                .template = "Explore Features",
            }),
        }),
    });
}

const Feature = struct { name: []const u8, detail: []const u8 };
fn FeatureSection() node.Node {
    const h2 = node.createNode(.h2);
    const div = node.createNode(.div).init(.{});
    const section = node.createNode(.section);

    const feature_list = [_]Feature{
        .{ .name = "Component System", .detail = "Build modern Web apps with Zig’s expressive component framework." },
        .{ .name = "Built-in Optimizations", .detail = "Automatic Wasm optimizations are all built-in" },
        .{ .name = "Tailwind CSS Support", .detail = "Tailwind CSS support. Currently through only Play CDN" },
        .{ .name = "Integrated Web Assembly", .detail = "Automatically generate Wasm from Zig and control it seamlessly on the Web." },
        .{ .name = "File System Based Routing", .detail = "Routing is clearly defined by file placement." },
        .{ .name = "Useful Dev Utils", .detail = "Boost productivity with our powerful developer-friendly CLI." },
    };

    return section.setId("features").setClass("py-16 px-8 bg-white dark:bg-gray-900").init(.{
        h2.setId("features-title")
            .setClass("text-4xl text-center font-[Orbitron] bg-gradient-to-r from-pink-500 via-red-500 to-yellow-500 bg-clip-text text-transparent")
            .init("Core Features"),
        inline for (feature_list) |f|
        {
            div.addChild(FeatureArticle(f));
        },
        div.setClass("grid grid-cols-1 md:grid-cols-3 gap-8 mt-8"),
    });
}

fn FeatureArticle(feature: Feature) node.Node {
    const h3 = node.createNode(.h3);
    const article = node.createNode(.article);
    const p = node.createNode(.p);
    return article.setClass("bg-gray-100 dark:bg-gray-800 p-6 rounded-lg shadow-md text-center").init(.{
        h3.setClass("text-2xl font-bold text-gray-900 dark:text-gray-100").init(feature.name),
        p.setClass("mt-4 text-gray-600 dark:text-gray-400").init(feature.detail),
    });
}

fn RoadMapSection() node.Node {
    const h2 = node.createNode(.h2);
    const ul = node.createNode(.ul);
    const li = node.createNode(.li);
    const section = node.createNode(.section);

    return section.setId("roadmap").setClass("py-16 px-8").init(.{
        h2
            .setId("roadmap-title")
            .setClass("text-4xl text-center font-[Orbitron] bg-gradient-to-r from-pink-400 via-purple-500 to-indigo-500 bg-clip-text text-transparent font-bold")
            .init("Development Roadmap"),
        ul.setClass("mt-8 space-y-4 text-gray-700 dark:text-gray-300 list-disc pl-12").init(.{
            li.setClass("text-lg").init("2024 Q1 - Initial Release"),
            li.setClass("text-lg").init("2024 Q2 - Feature Expansion"),
            li.setClass("text-lg").init("2025 - Community Integration"),
        }),
    });
}

fn FAQ() node.Node {
    const h2 = node.createNode(.h2);
    const div = node.createNode(.div).init(.{});
    const details = node.createNode(.details);
    const summary = node.createNode(.summary);
    const p = node.createNode(.p);
    const section = node.createNode(.section);

    const QA = struct { question: []const u8, answer: []const u8 };
    const qa = [_]QA{
        .{ .question = "What is zFrame?", .answer = "zframe is a bold experiment in modern Web development—a Zig-powered frontend framework that lets you harness WebAssembly without worrying about layers or boundaries." },
        .{ .question = "Do I need to know Zig?", .answer = "" },
    };

    return section.setId("faq").setClass("py-16 px-8").init(.{
        h2
            .setId("faq-title")
            .setClass("text-4xl text-center font-[Orbitron] bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 bg-clip-text text-transparent font-bold")
            .init("FAQ"),
        inline for (qa) |_qa|
        {
            div.addChild(
                details.setClass("p-4 bg-white dark:bg-gray-800 rounded-lg shadow-md").init(.{
                    summary.setClass("text-xl font-semibold text-gray-900 dark:text-white cursor-pointer").init(_qa.question),
                    p.setClass("mt-2 text-gray-600 dark:text-gray-300").init(_qa.answer),
                }),
            );
        },
        div.setClass("space-y-6 mt-8"),
    });
}

fn codeline(title: []const u8, comptime codes: []const u8) node.Node {
    const div = node.createNode(.div);
    const pre = node.createNode(.pre);
    const h3 = node.createNode(.h3);
    const code = node.createNode(.code).init(.{});

    return div.setClass("flex flex-col items-center bg-gradient-to-br from-gray-50 via-gray-100 to-gray-200 dark:from-gray-900 dark:via-gray-800 dark:to-gray-700 p-8 rounded-lg shadow-lg").init(.{
        h3.setClass("text-4xl text-center font-[Orbitron] bg-gradient-to-r from-teal-400 via-blue-500 to-purple-500 bg-clip-text text-transparent font-extrabold mb-6").init(title),
        div
            .setClass("bg-white dark:bg-gray-900 text-gray-800 dark:text-gray-300 p-6 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700")
            .init(
            .{
                code.init(.{
                    pre.setClass("text-sm leading-relaxed font-mono").init(codes),
                }),
            },
        ),
    });
}

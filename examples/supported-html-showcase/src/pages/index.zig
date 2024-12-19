const z = @import("zframe");
const c = @import("components");
const Head = c.head.Head;
const node = z.node;
const h = z.handler;
const WebAssembly = z.handler.WebAssembly;

fn index() node.Node {
    const html = node.createNode(.html);

    return html.setClass("").init(.{
        // .lang = "ja",
        node.createNode(.head).init(.{
            node.createNode(.title).init(.{"zframe - Zig Web Frontend Framework"}),
            node.createNode(.meta).init(.{ .description, "zFrame is Zig Web Frontend Framework." }),
            node.createNode(.meta).init(.{ .charset, "utf-8" }),
            node.createNode(.raw).init(.{
                \\<script src="https://cdn.tailwindcss.com"></script>
            }),
            node.createNode(.empty).init(.{}).iterate(.{}),
        }),
        node.createNode(.custom).define("only-one").init("custom element"),
        node.createNode(.link).init(.{ .href = "css/test.css", .rel = "stylesheet" }),
        // node.createNode(.base).init(.{.target="_blank", .href="https://hogehoge.com"}),
        // node.createNode(.style).init(.{}),
        node.createNode(.header).init(.{
            node.createNode(.menu).init(.{
                node.createNode(.ul).init(.{}),
                node.createNode(.nav).init(.{
                    node.createNode(.ol).init(.{
                        node.createNode(.li).init(.{node.createNode(.a).init(.{ .href = "/", .template = "index" })}),
                        node.createNode(.li).init(.{node.createNode(.a).init(.{ .href = "/about", .template = "about" })}),
                    }),
                }),
            }),
            node.createNode(.main).init(.{
                node.createNode(.article).init(.{
                    node.createNode(.h1).init("Heading 1"),
                    node.createNode(.span).init("hoge"),
                }),
                node.createNode(.section).init(.{
                    node.createNode(.h2).init("Heading 2"),
                }),
                node.createNode(.h3).init("Heading 3"),
                node.createNode(.h4).init("Heading 4"),
                node.createNode(.h5).init("Heading 5"),
                node.createNode(.h6).init("Heading 6"),
                node.createNode(.b).init("bold"),
                node.createNode(.em).init("strong"),
                node.createNode(.mark).init("marked"),
                node.createNode(.pre).init("preformatted"),
                // node.createNode(.q).init(.{
                // .cite="https://www.imdb.com/title/tt0062622/quotes/?item=qt0396921&ref_=ext_shr_lnk",
                //     .template="I'm sorry, Dave. I'm afraid I can't do that."
                // }),
                node.createNode(.s).init("strikethrough"),
                node.createNode(.figure).init(.{
                    node.createNode(.blockquote).init(.{
                        node.createNode(.i).init("italic"),
                    }),
                    node.createNode(.figcaption).init(.{
                        node.createNode(.cite).init(.{
                            node.createNode(.a).init(.{ .href = "http://www.george-orwell.org/1984/0.html", .template = "Nineteen Eighty-Four" }),
                        }),
                    }),
                }),
                node.createNode(.code).init("print(\"Hello World!\")"),
                node.createNode(.kbd).init("Shift"),
                node.createNode(.dialog).init(.{
                    node.createNode(.details).init(.{
                        node.createNode(.summary).init("sumarry"),
                    }),
                }),
                node.createNode(.h2).init("h2"),
                node.createNode(.h3).init("h3"),
                node.createNode(.h4).init("h4"),
                node.createNode(.h5).init("h5"),
                node.createNode(.h6).init("h6"),
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
                            node.createNode(.th).init(.{ .template = "Items", .scope = .col }),
                            node.createNode(.th).init(.{ .template = "Expenditure", .scope = .col }),
                        }),
                    }),
                    node.createNode(.tbody).init(.{
                        node.createNode(.tr).init(.{
                            node.createNode(.th).init(.{ .template = "Donuts", .scope = .row }),
                            node.createNode(.td).init("3,000"),
                        }),
                        node.createNode(.tr).init(.{
                            node.createNode(.th).init(.{ .template = "Stationery", .scope = .row }),
                            node.createNode(.td).init("18,000"),
                        }),
                    }),
                    node.createNode(.tfoot).init(.{
                        node.createNode(.tr).init(.{
                            node.createNode(.th).init(.{ .template = "Totals", .scope = .row }),
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
                            .type = .file,
                            .accept = ".pcap",
                            .required = true,
                        }).setId("pcapFile"),
                    }),
                    node.createNode(.label).init(.{
                        .template = "Choose",
                        // .forName="ice-cream-choice"
                    }),
                    node.createNode(.input).init(.{
                        .list = "ice-cream-flavors",
                        .name = "ice-cream-choice",
                    }).setId("ice-cream-choice"),
                    node.createNode(.datalist).init(.{
                        node.createNode(.option).init("Chocolate"),
                        node.createNode(.option).init("Mint"),
                    }).setId("ice-cream-flavors"),
                    node.createNode(.input).init(.{
                        .type = .submit,
                        .value = "subscribe!",
                    }).setId("button"),
                    // node.createNode(.button).init(.{
                    //     .type = .button,
                    //     .value = "subscribe!",
                    // }),
                }),
            }),
            // node.createNode(.table, caption, thead, tr, th, tbody, td, tfoot, col, colgroup,
            // node.createNode(.node.createNode(, fieldset, legend, meter, optgroup, option, output, progress, select, textarea,
            // node.createNode(.iframe, embed, fencedframe, object, picture, portal, source,
            // node.createNode(.address, aside, hgroup, search,
            // node.createNode(.blockquote, dd, dl, dt, figcaption, figure, hr,
            // node.createNode(.abbr, bdi, bdo, data, dfn, rp, rt, ruby, samp, small, strong, sub, sup, time, u, mathvar, wbr,
            // node.createNode(.area, audio, map, track, video,
            // node.createNode(.svg, math,
            // node.createNode(.canvas, noscript, script,
            // node.createNode(.del, ins,
            // node.createNode(.slot, template,
            node.createNode(.footer).init(.{}),
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

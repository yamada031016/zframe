const std = @import("std");

pub const Tag = enum {
    raw,
    header, footer, main,
    span, div, article,
    h1, h2, h3, h4, h5, h6,
    p, b, em, i, mark, pre, q, s,
    menu, ul, ol, li,
    nav,
    cite, code, kbd,
    details, summary,
    img,
    a,

    pub fn asText(tag: *const Tag) []const u8 {
        // std.debug.print("tag text: {any}\n", .{tag});
        return switch (tag.*) {
            .raw, .div => "div", .article => "article", .span => "span",
            .header => "header", .footer => "footer", .main => "main",
            .h1 => "h1", .h2 => "h2", .h3 => "h3", .h4 => "h4", .h5 => "h5", .h6 => "h6",
            .p => "p", .b => "b", .em => "em", .i => "i", .mark => "mark", .pre => "pre", .q => "q", .s => "s",
            .menu => "menu", .ul => "ul", .ol => "ol", .li => "li",
            .nav => "nav",
            .cite => "cite", .code => "code", .kbd => "kbd",
            .details => "details", .summary => "summary",
            .img => "img",
            .a => "a",
        };
    }
};

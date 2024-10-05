//! This module provides enum for definitions of HTML tags.
const std = @import("std");

// zig fmt: off
pub const Tag = enum {
    /// empty tag is unique in SSG-ZIG.
    /// empty tag is omitted when rendering its children.
    /// if you want writing raw html code, you should use raw tag.
    empty,
    /// raw tag is unique in SSG-ZIG.
    /// raw tag works like empty tag.
    /// raw tag is used for writing raw html code.
    raw,
    html,
    head, meta, title, link,
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
    table, caption, thead, tr, th, tbody, td, tfoot,

    pub fn asText(tag: *const Tag) []const u8 {
        return switch (tag.*) {
            .empty => "empty", .raw => "raw",
            .div => "div", .article => "article", .span => "span",
            .html => "html",
            .head => "head", .meta => "meta", .title => "title", .link => "link",
            .header => "header", .footer => "footer", .main => "main",
            .h1 => "h1", .h2 => "h2", .h3 => "h3", .h4 => "h4", .h5 => "h5", .h6 => "h6",
            .p => "p", .b => "b", .em => "em", .i => "i", .mark => "mark", .pre => "pre", .q => "q", .s => "s",
            .menu => "menu", .ul => "ul", .ol => "ol", .li => "li",
            .nav => "nav",
            .cite => "cite", .code => "code", .kbd => "kbd",
            .details => "details", .summary => "summary",
            .img => "img",
            .a => "a",
            .table => "table", .caption => "caption", .thead => "thead", .tr => "tr", .th => "th", .tbody => "tbody", .td => "td", .tfoot => "tfoot",
        };
    }
};
// zig fmt: on

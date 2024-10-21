//! This module provides enum for definitions of HTML tags.
const std = @import("std");

// zig fmt: off
pub const Tag = enum {
    custom,
    /// empty tag is unique in SSG-ZIG.
    /// empty tag is omitted when rendering its children.
    /// if you want writing raw html code, you should use raw tag.
    empty,
    /// raw tag is unique in SSG-ZIG.
    /// raw tag works like empty tag.
    /// raw tag is used for writing raw html code.
    raw,
    html,
    head, meta, title, link, base, style,
    header, footer, main,
    span, div, article, section,
    h1, h2, h3, h4, h5, h6,
    p, b, em, i, mark, pre, q, s,
    menu, ul, ol, li,
    nav,
    cite, code, kbd,
    details, summary, dialog,
    img,
    a,
    table, caption, thead, tr, th, tbody, td, tfoot, col, colgroup,
    form, input, button, label, datalist, fieldset, legend, meter, optgroup, option, output, progress, select, textarea,
    iframe, embed, fencedframe, object, picture, portal, source,
    address, aside, hgroup, search,
    blockquote, dd, dl, dt, figcaption, figure, hr,
    abbr, bdi, bdo, data, dfn, rp, rt, ruby, samp, small, strong, sub, sup, time, u, mathvar, wbr,
    area, audio, map, track, video,
    svg, math,
    canvas, noscript, script,
    del, ins,
    slot, template,

    pub fn asText(tag: *const Tag) []const u8 {
        return switch (tag.*) {
            .custom => "custom",
            .empty => "empty", .raw => "raw",
            .div => "div", .article => "article", .span => "span", .section => "section",
            .html => "html",
            .head => "head", .meta => "meta", .title => "title", .link => "link", .base=>"base", .style=>"style",
            .header => "header", .footer => "footer", .main => "main",
            .h1 => "h1", .h2 => "h2", .h3 => "h3", .h4 => "h4", .h5 => "h5", .h6 => "h6",
            .p => "p", .b => "b", .em => "em", .i => "i", .mark => "mark", .pre => "pre", .q => "q", .s => "s",
            .menu => "menu", .ul => "ul", .ol => "ol", .li => "li",
            .nav => "nav",
            .cite => "cite", .code => "code", .kbd => "kbd",
            .details => "details", .summary => "summary", .dialog => "dialog",
            .img => "img",
            .a => "a",
            .table => "table", .caption => "caption", .thead => "thead", .tr => "tr", .th => "th", .tbody => "tbody", .td => "td", .tfoot => "tfoot", .col=>"col", .colgroup=>"colgroup",
            .form=>"form", .input=>"input", .button=>"button", .label=>"label",.datalist=>"datalist", .fieldset=>"fieldset", .legend=>"legend", .meter=>"meter", .optgroup=>"optgroup", .option=>"option", .output=>"output", .progress=>"progress", .select=>"select", .textarea=>"textarea",
            .iframe=>"iframe", .embed=>"embed", .fencedframe=>"fencedframe", .object=>"object", .picture=>"picture", .portal=>"portal", .source=>"source",
            .address=>"address", .aside=>"aside", .hgroup=>"hgroup", .search=>"search",
            .blockquote=>"blockquote", .dd=>"dd", .dl=>"dl", .dt=>"dt", .figcaption=>"figcaption", .figure=>"figure", .hr=>"hr",
            .abbr=>"abbr", .bdi=>"bdi", .bdo=>"bdo", .data=>"data", .dfn=>"dfn", .rp=>"rp", .rt=>"rt", .ruby=>"ruby", .samp=>"samp", .small=>"small", .strong=>"strong", .sub=>"sub", .sup=>"sup", .time=>"time", .u=>"u", .mathvar=>"var", .wbr=>"wbr",
            .area=>"area", .audio=>"audio", .map=>"map", .track=>"track", .video=>"video",
            .svg=>"svg", .math=>"math",
            .canvas=>"canvas", .noscript=>"noscript", .script=>"script",
            .slot=>"slot", .template=>"template",
        };
    }
};
// zig fmt: on

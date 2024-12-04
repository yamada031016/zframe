//! This module provides structures and functions for representation of HTML elements.
const std = @import("std");
const Tag = @import("html.zig").Tag;

/// This function returns proper Element union.
pub fn createElement(comptime tagName: Tag) Element {
    return switch (tagName) {
        .img => Element{ .image = Image{} },
        .a => Element{ .hyperlink = HyperLink{} },
        .link => Element{ .link = Link{} },
        .meta => Element{ .meta = Meta{} },
        .custom => Element{ .custom = Custom{} },
        else => Element{
            .plane = PlaneElement{
                .tag = tagName,
            },
        },
    };
}

/// This enum definites types of Element.
/// These value is used at Element union as key.
pub const ElementType = enum {
    plane,
    image,
    hyperlink,
    link,
    meta,
    custom,
};

/// This union provides abstract interface for users
pub const Element = union(ElementType) {
    plane: PlaneElement,
    image: Image,
    hyperlink: HyperLink,
    link: Link,
    meta: Meta,
    custom: Custom,

    const TemplateError = error{
        TemplateNotSupport,
        TemplateNotSetting,
    };

    pub const ElementError = TemplateError;

    pub fn getTagName(self: *const Element) []const u8 {
        switch (self.*) {
            .plane => |p| return p.tag.asText(),
            .image => return "img",
            .hyperlink => return "a",
            .link => return "link",
            .meta => return "meta",
            .custom => return "custom",
        }
    }

    pub fn getTemplate(self: *const Element) ElementError![]u8 {
        switch (self.*) {
            .plane => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .hyperlink => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .custom => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .image, .link, .meta => return ElementError.TemplateNotSupport,
        }
    }
};

// add functions for checking validation.

/// This structure represents Generic HTML Element such as h1, p, and so on.
pub const PlaneElement = struct {
    pub const attributes = [_][]const u8{
        "accesskey",
        "contenteditable",
        "dir",
        "draggable",
        "hidden",
        "itemprop",
        "lang",
        "role",
        "slot",
        "spellcheck",
        "style",
        "title",
        "translate",
    };
    const Directionality = enum { leftToRight, RightToLeft, Auto };

    tag: Tag,
    template: ?[]u8 = null,

    accesskey: ?[]u8 = null,
    contenteditable: ?bool = null,
    dir: ?Directionality = null,
    draggable: ?bool = null,
    hidden: ?bool = null,
    itemprop: ?[]u8 = null,
    lang: ?[]u8 = null,
    role: ?[]u8 = null,
    slot: ?[]u8 = null,
    spellcheck: ?bool = null,
    style: ?[]u8 = null,
    title: ?[]u8 = null,
    translate: ?bool = null,
};

/// This structure represents image tag without any auto-optimization.
// add isValid() for check srcset, sizes...
pub const Image = struct {
    pub const attributes = [_][]const u8{
        "src",
        "alt",
        "width",
        "height",
        "attributionsrc",
        "crossorigin",
        "decoding",
        "elementtiming",
        "fetchpriority",
        "ismap",
        "loading",
        "referrerpolicy",
        "sizes",
        "srcset",
        "usemap",
    };

    const Crossorigin = enum {
        anonymous,
        useCredentials,
    };

    const Decoding = enum {
        Sync,
        Async,
        Auto,
    };

    const fetchPriority = enum {
        high,
        low,
        auto,
    };

    const Loading = enum {
        eager,
        lazy,
    };

    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        sameOrigin,
        strictOrigin,
        strictOriginWhenCrossOrigin,
        unsafeUrl,
    };

    src: ?[]u8 = null,
    alt: ?[]u8 = null,
    width: ?u16 = null,
    height: ?u16 = null,
    attributionsrc: ?[]u8 = null,
    crossorigin: ?Crossorigin = null,
    decoding: ?Decoding = null,
    elementtiming: ?[]u8 = null,
    fetchpriority: ?fetchPriority = null,
    ismap: ?bool = null,
    loading: ?Loading = null,
    referrerpolicy: ?referrerPolicy = null,
    sizes: ?[]u8 = null,
    srcset: ?[]u8 = null,
    usemap: ?[]u8 = null,
};

/// This structure represents anchor tag without any auto-optimization.
pub const HyperLink = struct {
    pub const attributes = [_][]const u8{
        "href",
        "target",
        "download",
        "rel",
        "hreflang",
        "ping",
        "referrerpolicy",
        "type",
        "attributionsrc",
    };

    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        sameOrigin,
        strictOrigin,
        strictOriginWhenCrossOrigin,
        unsafeUrl,
    };

    const Target = enum {
        self,
        blank,
        parent,
        top,
        unfencedTop,
    };
    const relValue = enum {
        alternate,
        author,
        bookmark,
        external,
        help,
        license,
        next,
        nofollow,
        noreferrer,
        noopener,
        prev,
        search,
        tag,
    };
    template: ?[]u8 = null,
    href: ?[]u8 = null,

    target: ?Target = null,
    download: ?[]u8 = null,
    rel: ?relValue = null,
    hreflang: ?[]u8 = null,
    ping: ?[]u8 = null,
    referrerpolicy: ?referrerPolicy = null,
    mimeType: ?[]u8 = null,
    attributionsrc: ?[]u8 = null,
};

/// This structure represents meta tag.
pub const Meta = struct {
    meta_type: ?MetaType = undefined,
    property: ?[]u8 = null,
    content: ?[]u8 = null,
    charset: ?[]u8 = null,

    pub const MetaType = enum {
        charset,

        description,
        viewport,
        keywords,
        property,
        twitter_card,
        twitter_site,
        twitter_creator,
        theme_color,

        pub fn asText(meta: *const MetaType) []const u8 {
            return switch (meta.*) {
                .charset => "charset",
                .description => "description",
                .viewport => "viewport",
                .keywords => "keywords",
                .property => "property",
                .twitter_card => "twitter_card",
                .twitter_site => "twitter_site",
                .twitter_creator => "twitter_creator",
                .theme_color => "theme_color",
            };
        }
    };
};

/// This structure represents link tag.
pub const Link = struct {
    pub const attributes = [_][]const u8{
        "as",
        "blocking",
        "crossorigin",
        "disabled", // for rel="stylesheet" only
        "fetchpriority",
        "href",
        "hreflang",
        "imagesizes", // for rel="preload" and as="image" only
        "imagesrcset", // for rel="preload" and as="image" only
        "integrity", // for rel="stylesheet" or "preload" or "modulepreload"
        "media",
        "referrerpolicy",
        "rel",
        "sizes",
        "title",
        "type",
    };

    // this attribute is required when rel="preload", optional when rel="modulepreload"
    const typeOfContent = enum {
        audio,
        document,
        embed,
        fetch,
        font,
        image,
        object,
        script,
        style,
        track,
        video,
        worker,
    };

    const Crossorigin = enum {
        anonymous,
        useCredentials,
    };

    const fetchPriority = enum {
        high,
        low,
        auto,
    };

    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        unsafeUrl,
    };

    rel: ?[]u8 = null,
    href: ?[]u8 = null,

    as: ?[]u8 = null,
    blocking: ?[]u8 = null,
    crossorigin: ?Crossorigin = null,
    disabled: ?bool = null, // for rel="stylesheet" only
    fetchpriority: ?fetchPriority = null,
    hreflang: ?[]u8 = null,
    imagesizes: ?[]u8 = null, // for rel="preload" and as="image" only
    imagesrcset: ?[]u8 = null, // for rel="preload" and as="image" only
    integrity: ?[]u8 = null, // for rel="stylesheet" or "preload" or "modulepreload"
    media: ?[]u8 = null,
    referrerpolicy: ?referrerPolicy = null,
    sizes: ?[]u8 = null,
    title: ?[]u8 = null,
    type: ?typeOfContent = null,
};

/// This structure represents Web Components's custom element.
pub const Custom = struct {
    template: ?[]u8 = null,
};

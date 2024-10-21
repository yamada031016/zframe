//! This module provides structures and functions for representation of HTML elements.
const std = @import("std");
const Tag = @import("html.zig").Tag;

/// This function returns proper Element union.
pub fn createElement(comptime tagName: Tag) Element {
    switch (tagName) {
        .img => {
            return Element{ .image = Image{} };
        },
        .a => {
            return Element{ .hyperlink = HyperLink{} };
        },
        .link => {
            return Element{ .link = Link{} };
        },
        .meta => {
            return Element{ .meta = Meta{} };
        },
        .custom => {
            return Element{ .custom = Custom{} };
        },
        else => {
            return Element{ .plane = PlaneElement{
                .tag = tagName,
            } };
        },
    }
}

/// This enum definites types of Element.
/// These value is used at Element union as key.
const ElementType = enum {
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

    pub const ElementError = error{
        TemplateNotSupport,
        TemplateNotSetting,
    };

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

// add functions checking validation.

/// This structure represents Generic HTML Element such as h1, p, and so on.
pub const PlaneElement = struct {
    const Self = @This();

    tag: Tag,
    template: ?[]u8 = null,
};

/// This structure represents image tag without any auto-optimization.
// add isValid() for check srcset, sizes...
pub const Image = struct {
    const Self = @This();
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

    const decoding = enum {
        Sync,
        Async,
        Auto,
    };

    const crossorigin = enum {
        anonymous,
        useCredentials,
    };

    const fetchPriority = enum {
        high,
        low,
        auto,
    };

    const loading = enum {
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
};

/// This structure represents anchor tag without any auto-optimization.
pub const HyperLink = struct {
    const Self = @This();
    pub const attributes = [_][]const u8{ "href", "target", "download", "rel", "hreflang", "ping", "referrerpolicy", "type", "attributionsrc" };

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

    const target = enum {
        self,
        blank,
        parent,
        top,
        unfencedTop,
    };
    template: ?[]u8 = null,
    href: ?[]u8 = null,
};

/// This structure represents meta tag.
pub const Meta = struct {
    const Self = @This();

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
    const Self = @This();
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

    const crossorigin = enum {
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
};

/// This structure represents Web Components's custom element.
/// usecase
/// const custom = createNode(.custom);
/// const custom_button = custom.setId("custom-button");
/// custom_button.init(.{})
pub const Custom = struct {
    const Self = @This();

    template: ?[]u8 = null,
};

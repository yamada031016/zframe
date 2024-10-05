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
};

/// This structure represents Generic HTML Element such as h1, p, and so on.
pub const PlaneElement = struct {
    const Self = @This();

    tag: Tag,
    template: ?[]u8 = null,
};

/// This structure represents image tag without any auto-optimization.
pub const Image = struct {
    const Self = @This();
    pub const attributes = [_][]const u8{ "src", "alt", "width", "height" };

    src: ?[]u8 = null,
    alt: ?[]u8 = null,
    width: ?u16 = null,
    height: ?u16 = null,
};

/// This structure represents anchor tag without any auto-optimization.
pub const HyperLink = struct {
    const Self = @This();
    pub const attributes = [_][]const u8{"href"};

    template: ?[]u8 = null,
    href: ?[]u8 = null,
    lazy: bool = false,
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
    // style: ?[]u8 = null,
    // eventListener: ?[]u8 = null,
    // callback: ?[]u8 = null,
};

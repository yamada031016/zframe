const std = @import("std");
const Tag = @import("html.zig").Tag;

pub fn createElement(comptime tagName: Tag) Element {
     switch (tagName) {
        .img => {
            return Element{
                .image = Image{}
            };
        },
        .a => {
            return Element{
                .link = Link{}
            };
        },
        else => {
            return Element{
                .plane = PlaneElement{
                    .tag = tagName,
                }
            };
        },
    }
}

const ElementType = enum {
    plane,
    image,
    link,
};

pub const Element = union(ElementType) {
    plane: PlaneElement,
    image: Image,
    link: Link,
};

pub const PlaneElement = struct {
    const Self = @This();

    tag: Tag,
    template: ?[]u8 = null,
    children: ?[]Self = null,
    class: ?[]u8 = null,
    id: ?[]u8 = null,
};

pub const Image = struct {
    const Self = @This();

    class: ?[]u8 = null,
    id: ?[]u8 = null,
    src: ?[]u8 = null,
    alt: ?[]u8 = null,
};


pub const Link = struct {
    const Self = @This();

    class: ?[]u8 = null,
    id: ?[]u8 = null,
    template: ?[]u8 = null,

    href: ?[]u8 = null,
    lazy: bool = false,
};

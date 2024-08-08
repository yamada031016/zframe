const std = @import("std");
const Tag = @import("html.zig").Tag;

pub fn createElement(comptime tagName: Tag) Element {
     switch (tagName) {
        .img => {
            return Element{
                .image = Image{}
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
};

pub const Element = union(ElementType) {
    plane: PlaneElement,
    image: Image,
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


const std = @import("std");
const zframe = @import("zframe");
const node = zframe.node;
const Node = node.Node;

pub fn Button() Node {
    const button = node.createNode(.button);
    const p = node.createNode(.p);
    const div = node.createNode(.div);
    return div.setClass("border border-gray-200 rounded w-20 h-8 text-center").init(.{
        button.init(.{
            p.setClass("text-center").init("click me"),
        }),
    });
}

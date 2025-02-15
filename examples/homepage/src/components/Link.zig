const zframe = @import("zframe");
const node = zframe.node;
const Node = node.Node;
const std = @import("std");

const NodeFunc = fn (anytype) Node;

pub fn Link(root: []const u8) NodeFunc {
    return struct {
        fn hyperlink(args: anytype) Node {
            const _args = .{
                .template = if (@hasField(@TypeOf(args), "template")) @field(args, "template") else null,
                .href = if (@hasField(@TypeOf(args), "href")) root ++ @field(args, "href") else null,
                .target = if (@hasField(@TypeOf(args), "target")) @field(args, "target") else null,
                .download = if (@hasField(@TypeOf(args), "download")) @field(args, "download") else null,
                .rel = if (@hasField(@TypeOf(args), "rel")) @field(args, "rel") else null,
                .hreflang = if (@hasField(@TypeOf(args), "hreflang")) @field(args, "hreflang") else null,
                .ping = if (@hasField(@TypeOf(args), "ping")) @field(args, "ping") else null,
                .referrerpolicy = if (@hasField(@TypeOf(args), "referrerpolicy")) @field(args, "referrerpolicy") else null,
                .mimeType = if (@hasField(@TypeOf(args), "mimeType")) @field(args, "mimeType") else null,
                .attributionsrc = if (@hasField(@TypeOf(args), "attributionsrc")) @field(args, "attributionsrc") else null,
            };
            const a = node.createNode(.a);
            return a.init(_args);
        }
    }.hyperlink;
}

const std = @import("std");
const allocator = std.heap.wasm_allocator;

pub const Buffer = packed struct {
    ptr: [*]u8,
    len: usize = 0,
    cap: usize,

    pub fn init(cap: usize) Buffer {
        const memory = allocator.alloc(u8, cap) catch unreachable;
        return Buffer{ .ptr = memory.ptr, .cap = cap };
    }
};

export var buffer: *Buffer = undefined;

export fn set(buf: *Buffer) void {
    buffer = buf;
}

export fn create(cap: usize) *Buffer {
    return @constCast(&Buffer.init(cap));
}

const std = @import("std");
const allocator = std.heap.wasm_allocator;

pub fn main() !void {
    return;
}

const Buffer = packed struct {
    ptr: [*]u8,
    len: usize = 0,
    cap: usize,

    pub fn init(cap: usize) Buffer {
        const memory = allocator.alloc(u8, cap) catch unreachable;
        return Buffer{ .ptr = memory.ptr, .cap = cap };
    }
};

var buffer: *Buffer = undefined;

export fn set(buf: *Buffer) void {
    buffer = buf;
}

export fn create(cap: usize) *Buffer {
    return @constCast(&Buffer.init(cap));
}

pub export fn hello() void {
    const result = "Hello Wasm!";
    buffer.len = result.len;
    buffer.ptr = @constCast(result.ptr);
    // dest.len = result.len;
    // dest.ptr = @constCast(result.ptr);
}

export fn add(a: u8, b: u8) u8 {
    return a + b;
}

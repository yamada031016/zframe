const func = @import("func.zig");

pub fn main() !void {
    return;
}

const Buffer = @import("Buffer.zig").Buffer;
extern var buffer: *Buffer;

pub export fn hello() void {
    const result = "Hello Wasm!";
    buffer.len = result.len;
    buffer.ptr = @constCast(result.ptr);
}

pub export fn add(a: u8, b: u8) u8 {
    return a + b;
}


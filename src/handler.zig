//! This module provides structures and functions for
const std = @import("std");
const wasm = std.wasm;

pub const Handler = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    filename: []const u8,
    env: wasm.Memory,

    pub fn init(comptime filename: []const u8) Handler {
        return .{
            .filename = filename,
            .env = wasm.Memory{ .limits = .{
                .flags = 0,
                .min = 256,
                .max = 256,
            } },
        };
    }

    pub fn toJS(self: Handler) ![]const u8 {
        const js = try std.fmt.allocPrint(std.heap.page_allocator, "const env={{memory:new WebAssembly.Memory({{initial:{},maximum:{}}})}};var memory=env.memory;WebAssembly.instantiateStreaming(fetch('api/{s}'),{{env}}).then(obj=>{{console.log(obj.instance.exports.one())}})", .{ self.env.limits.min, self.env.limits.max, self.filename });
        return js;
    }
};

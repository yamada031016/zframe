//! This module provides structures and functions for
const std = @import("std");
const wasm = std.wasm;

pub const Handler = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    filename: []const u8,
    env: wasm.Memory,

    pub fn init(filename: []const u8) Handler {
        return .{
            .filename = filename,
            .env = wasm.Memory{ .limits = .{
                .flags = 0,
                .min = 0,
                .max = 1,
            } },
        };
    }

    pub fn toJS(self: Handler) ![]const u8 {
        const js = try std.fmt.allocPrint(std.heap.page_allocator, "const env={{memory:new WebAssembly.Memory({{initial:{},maximum:{})}};var memory=env.memory;WebAssembly.instantiateStreaming(fetch('{s}'),{{env}}).then(obj=>{{}})", .{ self.env.limits.min, self.env.limits.max, self.filename });
        return js;
    }
};

// const env = {
//   memory: new WebAssembly.Memory({initial: 256, maximum: 256}),
// };
// var memory = env.memory;
// WebAssembly.instantiateStreaming(
//   fetch("add.wasm"),
//   {env}
// ).then(obj => {
//     // const a = document.getElementById("1").value
//     // const b = document.getElementById("2").value
//     // console.log(a, b)
//     var res = obj.instance.exports.add(a, b)
//     p.textContent = res
//     // console.log(res)
//   });

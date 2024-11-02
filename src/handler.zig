//! This module provides structures and functions for
const std = @import("std");
const wasm = std.wasm;

pub const Handler = union(HandlerType) {
    webassembly: WasmHandler,
    javascript: JsHandler,

    pub fn init(comptime target: HandlerType, comptime contents: anytype) Handler {
        switch (target) {
            .webassembly => {
                return Handler{
                    .webassembly = WasmHandler.init(contents),
                };
            },
            .javascript => {
                switch (@typeInfo(@TypeOf(contents))) {
                    .Struct => |s| {
                        if (!s.is_tuple) {
                            return Handler{
                                .javascript = JsHandler{
                                    .filename = @field(contents, "filename"),
                                    .func = @field(contents, "func"),
                                },
                            };
                        }
                        unreachable;
                    },
                    else => unreachable,
                }
            },
        }
    }
};

const HandlerType = enum {
    webassembly,
    javascript,
};

pub const WasmHandler = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    filename: []const u8,
    env: wasm.Memory,
    then: ?JsHandler = null,
    err: ?JsHandler = null,

    pub fn init(contents: anytype) WasmHandler {
        switch (@typeInfo(@TypeOf(contents))) {
            .Struct => |s| {
                if (!s.is_tuple) {
                    const then = if (@hasField(@TypeOf(contents), "then")) @field(contents, "then") else null;
                    return .{
                        .filename = @field(contents, "filename"),
                        .env = wasm.Memory{
                            .limits = .{
                                .flags = 0,
                                .min = 256,
                                .max = 256,
                            },
                        },
                        .then = then,
                    };
                }
                unreachable;
            },
            else => {
                // expect only Handler.init("filename");
                return .{
                    .filename = contents,
                    .env = wasm.Memory{
                        .limits = .{
                            .flags = 0,
                            .min = 256,
                            .max = 256,
                        },
                    },
                };
            },
        }
    }

    pub fn toJS(self: WasmHandler) ![]const u8 {
        const then = if (self.then) |th| th.func else "";
        const js = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "const env={{memory:new WebAssembly.Memory({{initial:{},maximum:{}}})}};var memory=env.memory;WebAssembly.instantiateStreaming(fetch('api/{s}'),{{env}}).then({s})",
            .{ self.env.limits.min, self.env.limits.max, self.filename, then },
        );
        return js;
    }
};

pub const JsHandler = struct {
    filename: []const u8,
    func: []const u8,
    pub const events = [_][]const u8{
        "click",
        "keydown",
        "keyup",
        "mousedown",
        "mouseup",
        "mousemove",
        "mouseover",
        "mouseout",
        "onLoad",
        "onUnload",
        "focus",
        "blur",
        "submit",
        "reset",
        "change",
        "resize",
        "abort",
        "error",
        "load",
    };
};

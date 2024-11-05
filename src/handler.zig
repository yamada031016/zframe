//! This module provides structures and functions for
const std = @import("std");
const wasm = std.wasm;

/// WebAssembly wrapper
pub const WebAssembly = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    filename: []const u8,
    env: wasm.Memory,
    handler: JsHandler,

    pub fn init(filename: []const u8, handler: JsHandler) WebAssembly {
        return .{
            .filename = filename,
            .env = wasm.Memory{
                .limits = .{
                    .flags = 0,
                    .min = 256,
                    .max = 256,
                },
            },
            .handler = handler,
        };
    }

    pub fn toJS(self: WebAssembly) ![]const u8 {
        const then = if (self.handler.then) |th| th.func else "";
        const js = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "const env={{memory:new WebAssembly.Memory({{initial:{},maximum:{}}})}};var memory=env.memory;WebAssembly.instantiateStreaming(fetch('api/{s}'),{{env}}).then({s})",
            .{ self.env.limits.min, self.env.limits.max, self.filename, then },
        );
        return js;
    }
};

pub const JsWrapper = struct {
    filename: []const u8,
    func: []const u8,
    pub const events = enum {
        click,
        keydown,
        keyup,
        mousedown,
        mouseup,
        mousemove,
        mouseover,
        mouseout,
        onLoad,
        onUnload,
        focus,
        blur,
        submit,
        reset,
        change,
        resize,
        abort,
        Error,
        load,
    };
};

pub const JsHandler = struct {
    then: ?JsWrapper = null,
    err: ?JsWrapper = null,
};

const loadContents = enum {
    webassembly,
    javascript,
};

pub const Loader = union(loadContents) {
    webassembly: WebAssembly,
    javascript: JsWrapper,
};

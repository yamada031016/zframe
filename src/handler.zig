//! This module provides structures and functions for
const std = @import("std");
const wasmBinaryAnalyzer = @import("wasm-binary-analyzer");
const wasm = std.wasm;

/// WebAssembly wrapper
pub const WebAssembly = struct {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    filename: []const u8,
    env: wasm.Memory,
    handler: JsHandler,

    pub fn init(filename: []const u8, handler: JsHandler) WebAssembly {
        var buf: [4096]u8 = undefined;
        const wasm_path = std.fmt.allocPrint(std.heap.page_allocator, "zig-out/html/api/{s}", .{filename}) catch @panic("failed to format string");
        const file = std.fs.cwd().openFile(wasm_path, .{}) catch @panic("failed to open webassebmly file");
        defer file.close();
        const size = file.readAll(&buf);

        var Wasm = wasmBinaryAnalyzer.init(std.heap.page_allocator.dupe(u8, buf[0..size]) catch unreachable, size);
        if (Wasm.analyzeSection(.Memory)) |mem| {
            std.debug.print("mem info: {any}\n", .{mem[0]});
        } else |_| {}
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

    pub fn deinit(_: WebAssembly) void {
        _ = gpa.deinit();
    }

    pub fn toJavaScript(self: WebAssembly) ![]const u8 {
        const then = if (self.handler.then) |then| then.func else "";
        const js = try std.fmt.allocPrint(
            allocator,
            "const env={{memory:new WebAssembly.Memory({{initial:{},maximum:{}}})}};var memory=env.memory;WebAssembly.instantiateStreaming(fetch('api/{s}'),{{env}}).then({s})",
            .{ self.env.limits.min, self.env.limits.max, self.filename, then },
        );
        return js;
    }
};

pub const JsWrapper = struct {
    filename: []const u8,
    func: []const u8,
};

pub const JsHandler = struct {
    then: ?JsWrapper = null,
    err: ?JsWrapper = null,
};

pub const EventListener = struct {
    target: EventTypes,
    content: Loader,
    options: ?Options = null,
    pub const EventTypes = enum {
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
    pub const Options = enum {
        capture,
        once,
        passive,
        signal,
        useCapture,
        wantsUntrusted, // firefox only
    };
};

const loadContents = enum {
    webassembly,
    javascript,
};

pub const Loader = union(loadContents) {
    webassembly: WebAssembly,
    javascript: JsWrapper,
};

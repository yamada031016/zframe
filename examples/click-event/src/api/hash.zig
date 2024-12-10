const std = @import("std");
const wasm = @import("wasm.zig");

pub export var MEMORY: [65536]u8 = [_]u8{0} ** 65536;

pub export fn hash(top: u32, len: u32) u8 {
    var sha256 = std.crypto.hash.sha2.Sha256.init(.{});
    const value = MEMORY[top .. top + len];
    sha256.update(value);
    const result = sha256.finalResult();
    @memcpy(MEMORY[top + len ..].ptr, &result);
    return result.len;
}
pub export fn getOffset() *u8 {
    return &MEMORY[0];
}

export fn wasmAnalyze(top: u32, len: u32) u8 {
    const data = MEMORY[top .. top + len];
    var Wasm = wasm.Wasm.init(data, data.len);

    var data_len = data.len;
    if (Wasm.analyzeSection(.Type)) |typeInfo| {
        const type_section = "type section info: ";
        @memcpy(MEMORY[top + data_len ..].ptr, type_section);
        data_len += type_section.len;
        for (0..typeInfo.len) |i| {
            MEMORY[top + data_len] = '(';
            data_len += 1;
            for (typeInfo[i].args_type) |args| {
                const args_type = args.toString();
                @memcpy(MEMORY[top + data_len ..].ptr, args_type);
                data_len += args_type.len;
                MEMORY[top + data_len] = ' ';
                data_len += 1;
            }
            MEMORY[top + data_len] = ')';
            data_len += 1;

            const result_header = " ->";
            @memcpy(MEMORY[top + data_len ..].ptr, result_header);
            data_len += result_header.len;
            for (typeInfo[i].result_type) |result| {
                const result_type = result.toString();
                @memcpy(MEMORY[top + data_len ..].ptr, result_type);
                data_len += result_type.len;
            }
            MEMORY[top + data_len] = ' ';
            data_len += 1;
        }
    } else |_| {}
    // if (Wasm.analyzeSection(.Memory)) |mem| {
    // std.debug.print("mem info: {any}\n", .{mem});
    // } else |_| {}
    return @intCast(data_len - data.len);
}

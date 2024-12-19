//! Wasmファイルの読み取りをする
const std = @import("std");
const leb128 = @import("leb128.zig");
const Runtime = @import("runtime.zig").Runtime;
const c = @import("code.zig");
const utils = @import("utils.zig");
const s = @import("section_info.zig");
const Section = s.Section;

// Wasmファイルの読み取りに関する構造体
pub const Wasm = struct {
    runtime: *Runtime,
    data: []u8,
    size: usize,
    pos: usize = 0,

    pub fn init(data: []u8, size: usize) Wasm {
        return Wasm{
            .data = data,
            .size = size,
            .runtime = Runtime.init(data),
        };
    }

    // secで指定されたセクションまで読み進める
    fn proceedToSection(self: *Wasm, sec: Section) void {
        self.pos = 8;
        if (sec == Section.Type)
            return;
        // std.debug.print("{}:{any}\n", .{ @intFromEnum(sec), self.data[0 .. self.pos + 20] });

        for (0..@intFromEnum(sec)) |id| {
            // std.debug.print("before: {}:{any}\n", .{ (id), self.data[self.pos .. self.pos + 20] });
            if (self.getSize(@enumFromInt(id))) |section| {
                self.pos += section.size + 1 + section.byte_width;
            } else |err| {
                switch (err) {
                    WasmError.SectionNotFound => {},
                    else => unreachable,
                }
            }
        }
    }

    fn proceedToCodeFunc(self: *Wasm) void {
        const local_var_cnt = utils.getValCounts(self.data, self.pos);
        const local_var_width = calcWidth: {
            var cnt = local_var_cnt;
            var i: usize = 1;
            while (cnt > 128) : (i += 1) {
                cnt /= 128;
            }
            break :calcWidth i;
        };
        self.pos += local_var_width;
        for (0..local_var_cnt) |_| {
            for (self.data[self.pos..], 1..) |val, j| {
                if (val < 128) {
                    self.pos += j; // ローカル変数のサイズのバイト幅だけ進める(最大u32幅)
                    break;
                }
            }
            self.pos += 1; // valtype分進める
        }
    }

    pub fn analyzeSection(self: *Wasm, comptime sec: Section) !switch (sec) {
        .Type => []s.TypeSecInfo,
        .Memory => s.MemorySecInfo,
        .Import => []s.ImportSecInfo,
        .Export => []s.ExportSecInfo,
        else => void,
    } {
        // std.debug.print("{any}\n", .{self.data[0..10]});
        // defer std.debug.print("{any}\n", .{self.data[0..10]});
        self.proceedToSection(sec);

        const section = self.getSize(sec) catch |err| switch (err) {
            WasmError.SectionNotFound => {
                switch (sec) {
                    // .Type => {
                    //     const dummy: [1]s.TypeSecInfo = undefined;
                    //     return try std.heap.page_allocator.dupe(s.TypeSecInfo, dummy[0..0]);
                    // },
                    // .Memory => {
                    //     const dummy: s.MemorySecInfo = undefined;
                    //     return dummy;
                    // },
                    // .Import => {
                    //     const dummy: [1]s.ImportSecInfo = undefined;
                    //     return try std.heap.page_allocator.dupe(s.ImportSecInfo, dummy[0..0]);
                    // },
                    // .Export => {
                    //     const dummy: [1]s.ExportSecInfo = undefined;
                    //     return try std.heap.page_allocator.dupe(s.ExportSecInfo, dummy[0..0]);
                    // },
                    else => return err,
                }
            },
        };

        self.pos += 1 + section.byte_width; // idとサイズのバイト数分進める

        switch (sec) {
            .Type => {
                const cnt = try self.calcLEB128Data(); // number of function types
                var _typeInfo: [32]s.TypeSecInfo = undefined;
                for (0..cnt) |j| {
                    _ = try self.calcLEB128Data(); // expect 60: indicate function type below.
                    const args_len = try self.calcLEB128Data();
                    var args: [32]s.TypeSecInfo.TypeEnum = undefined;
                    if (args_len == 0) {
                        args[0] = .wasm_void;
                    } else {
                        for (0..args_len) |i| {
                            args[i] = switch (try self.calcLEB128Data()) {
                                0x0 => .wasm_void,
                                0x7e => .wasm_i64,
                                0x7f => .wasm_i32,
                                else => .wasm_unknown,
                            };
                        }
                    }
                    const return_len = try self.calcLEB128Data();
                    var returns: [32]s.TypeSecInfo.TypeEnum = undefined;
                    if (return_len == 0) {
                        returns[0] = .wasm_void;
                    } else {
                        for (0..return_len) |i| {
                            returns[i] = switch (try self.calcLEB128Data()) {
                                0x0 => .wasm_void,
                                0x7e => .wasm_i64,
                                0x7f => .wasm_i32,
                                else => .wasm_unknown,
                            };
                        }
                    }
                    _typeInfo[j] = .{
                        .args_type = try std.heap.page_allocator.dupe(s.TypeSecInfo.TypeEnum, args[0..args_len]),
                        .result_type = try std.heap.page_allocator.dupe(s.TypeSecInfo.TypeEnum, returns[0..return_len]),
                    };
                }
                return try std.heap.page_allocator.dupe(s.TypeSecInfo, _typeInfo[0..cnt]);
            },
            .Memory => {
                var _mem: s.MemorySecInfo = undefined;
                const mem_min_size = try self.calcLEB128Data();
                const mem_max_size = try self.calcLEB128Data();
                _mem = .{
                    .min_size = mem_min_size,
                    .max_size = mem_max_size,
                };
                return _mem;
            },
            .Import => {
                var importInfo: [32]s.ImportSecInfo = undefined;
                const import_count = try self.calcLEB128Data();
                for (0..import_count) |cnt| {
                    const module_name_length = try self.calcLEB128Data();
                    const module_name = name: {
                        var tmp: [32]u8 = undefined;
                        for (self.data[self.pos .. self.pos + module_name_length], 0..) |char, i| {
                            tmp[i] = char;
                            self.pos += 1;
                        }
                        break :name &tmp;
                    };
                    const import_name_length = try self.calcLEB128Data();
                    const import_name = name: {
                        var tmp: [32]u8 = undefined;
                        for (self.data[self.pos .. self.pos + import_name_length], 0..) |char, i| {
                            tmp[i] = char;
                            self.pos += 1;
                        }
                        break :name &tmp;
                    };
                    const target_section = try self.calcLEB128Data();
                    const target_section_id = try self.calcLEB128Data();
                    importInfo[cnt] = .{
                        .module_name = module_name,
                        .import_name = import_name,
                        .target_section = target_section,
                        .target_section_id = target_section_id,
                    };
                }
                return try std.heap.page_allocator.dupe(s.ImportSecInfo, importInfo[0..import_count]);
            },
            .Export => {
                var exportInfo: [32]s.ExportSecInfo = undefined;
                const export_count = try self.calcLEB128Data();
                for (0..export_count) |cnt| {
                    const export_name_length = try self.calcLEB128Data();
                    const export_name = name: {
                        var tmp: [32]u8 = undefined;
                        for (self.data[self.pos .. self.pos + export_name_length], 0..) |char, i| {
                            tmp[i] = char;
                            self.pos += 1;
                        }
                        break :name &tmp;
                    };
                    const target_section = try self.calcLEB128Data();
                    const target_section_id = try self.calcLEB128Data();
                    exportInfo[cnt] = .{
                        .name = export_name,
                        .target_section = target_section,
                        .target_section_id = target_section_id,
                    };
                }
                return try std.heap.page_allocator.dupe(s.ExportSecInfo, exportInfo[0..export_count]);
            },
            .Code => {
                var tmp = [_]u8{0} ** 4;
                for (self.data[self.pos..], 0..) |val, j| {
                    tmp[j] = val;
                    if (val < 128) {
                        self.pos += j + 1; // code count分進める
                        break;
                    }
                }

                const cnt = leb128.decodeLEB128(&tmp); // codeの数
                std.debug.print("{}個のcodeがあります.\n", .{cnt});

                var code: SectionSize = undefined;
                for (0..cnt) |i| {
                    code = c.getCodeSize(self.data, self.size, self.pos);
                    std.debug.print("({:0>2}) size: {} bytes\n", .{ i + 1, code.size });
                    self.pos += code.byte_width;

                    const local_var_cnt = utils.getValCounts(self.data, self.pos);
                    const local_var_width = calcWidth: {
                        var _cnt = local_var_cnt;
                        var j: usize = 1;
                        while (_cnt > 128) : (j += 1) {
                            _cnt /= 128;
                        }
                        break :calcWidth j;
                    };
                    self.pos += local_var_width;
                    for (0..local_var_cnt) |_| {
                        for (self.data[self.pos..], 1..) |val, k| {
                            if (val < 128) {
                                self.pos += k; // ローカル変数のサイズのバイト幅だけ進める(最大u32幅)
                                break;
                            }
                        }
                        self.pos += 1; // valtype分進める
                    }

                    // try self.runtime.execute(self.data[self.pos..]);
                    self.pos += code.size + code.byte_width;
                }
            },
            else => {},
        }
    }

    // コードを実行する
    fn execute(self: *Wasm, cnt: usize) !void {
        var code: SectionSize = undefined;
        var first_pos: usize = self.pos; // code sizeの位置を指している
        std.debug.print("{any}", .{self.data});
        for (0..cnt) |i| {
            code = c.getCodeSize(self.data, self.size, self.pos);
            std.debug.print("({:0>2}) size: {} bytes\n", .{ i + 1, code.size });
            self.pos += code.byte_width;

            self.proceedToCodeFunc();

            try self.runtime.execute(self.pos, first_pos + code.byte_width + code.size - 1);
            self.pos = first_pos + code.size + code.byte_width;
            first_pos = self.pos;
        }
    }

    fn getSize(self: *Wasm, sec: Section) !SectionSize {
        var section_size = SectionSize{ .size = 0, .byte_width = 0 };
        if (@intFromEnum(sec) == self.data[self.pos]) {
            const section = get_section_size: {
                var tmp = [_]u8{0} ** 4;
                for (self.data[self.pos + 1 ..], 0..) |val, j| {
                    tmp[j] = val;
                    if (val < 128) {
                        section_size.byte_width = j + 1;
                        break;
                    }
                }
                break :get_section_size &tmp;
            };
            section_size.size = leb128.decodeLEB128(@constCast(section));
            return section_size;
        } else {
            return WasmError.SectionNotFound;
        }
    }

    fn calcLEB128Data(self: *Wasm) !u32 {
        var buf = std.io.fixedBufferStream(self.data[self.pos..]);
        const val = try std.leb.readULEB128(u32, buf.reader());
        self.pos += buf.pos;
        return val;
    }
};

pub const WasmError = error{
    SectionNotFound,
};

pub const SectionSize = struct {
    size: usize,
    byte_width: usize,
};

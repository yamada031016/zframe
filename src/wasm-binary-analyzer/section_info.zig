const std = @import("std");
const wasm = std.wasm;

pub const Section = enum(u4) {
    const Self = @This();

    Custom = 0,
    Type = 1,
    Import = 2,
    Function = 3,
    Table = 4,
    Memory = 5,
    Global = 6,
    Export = 7,
    Start = 8,
    Element = 9,
    Code = 10,
    Data = 11,
    DataCount = 12,

    pub fn init(id: usize) Self {
        return @enumFromInt(id);
    }

    pub fn asText(self: Section) []const u8 {
        return switch (self) {
            .Custom => "custom section",
            .Type => "type section",
            .Import => "import section",
            .Function => "function section",
            .Table => "table section",
            .Memory => "memory section",
            .Global => "global section",
            .Export => "export section",
            .Start => "start section",
            .Element => "element section",
            .Code => "code section",
            .Data => "data section",
            .DataCount => "data count section",
        };
    }
};

pub const TypeSecInfo = struct {
    args_type: []TypeEnum,
    result_type: []TypeEnum,

    pub const TypeEnum = enum {
        wasm_void,
        wasm_unknown,
        wasm_i32,
        wasm_i64,

        pub fn toString(self: *const TypeEnum) []u8 {
            return switch (self.*) {
                .wasm_void => @constCast("void"),
                .wasm_unknown => unreachable,
                .wasm_i32 => @constCast("i32"),
                .wasm_i64 => @constCast("i64"),
            };
        }
    };
};

pub const MemorySecInfo = struct {
    min_size: u32,
    max_size: u32,
};

pub const ImportSecInfo = struct {
    module_name: []const u8,
    import_name: []const u8,
    target_section: u32,
    target_section_id: u32,
};

pub const ExportSecInfo = struct {
    name: []const u8,
    target_section: u32,
    target_section_id: u32,
};

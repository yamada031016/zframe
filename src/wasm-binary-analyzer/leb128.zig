//! LEB128デコードをする
const std = @import("std");

// LEB128でデコードし、結果を返す
pub fn decodeLEB128(data: []u8) usize {
    var num: usize = undefined;
    var decoded_number: usize = 0;
    for (data, 0..) |value, i| {
        num = value & 0b0111_1111; // 値の下位7bit
        decoded_number |= num << @intCast(i * 7); // 128倍して加える

        if (value >> 7 == 0) {
            // 上位1bitが0ならデコード終了
            break;
        }
    }
    return decoded_number;
}

pub fn decodesLEB128(data: []u8) isize {
    var num: isize = undefined;
    var decoded_number: isize = 0;
    var top_digit: u6 = 0;
    for (data, 0..) |value, i| {
        num = value & 0b0111_1111; // 値の下位7bit
        decoded_number |= num << @intCast(i * 7); // 128倍して加える
        top_digit += 1;

        if (value >> 7 == 0) {
            // 上位1bitが0
            if (decoded_number >> top_digit * 6 == 1) {
                decoded_number = switch (top_digit) {
                    1 => @as(i8, @truncate(decoded_number | 1 << 7)),
                    2 => @as(i16, @truncate(decoded_number | 1 << 14)),
                    3 => @as(i24, @truncate(decoded_number | 1 << 21)),
                    4 => @as(i32, @truncate(decoded_number | 1 << 28)),
                    5 => @as(i40, @truncate(decoded_number | 1 << 35)),
                    6 => @as(i48, @truncate(decoded_number | 1 << 42)),
                    7 => @as(i56, @truncate(decoded_number | 1 << 49)),
                    8 => @as(i64, @truncate(decoded_number | 1 << 56)),
                    else => unreachable,
                };
            }
            break;
        }
    }
    return decoded_number;
}

pub fn decodeArrayByLEB128(data: []u8, pos: usize) usize {
    var tmp = [_]u8{0} ** 4;
    for (data[pos..], 0..) |val, j| {
        tmp[j] = val;
        if (val < 128) {
            break;
        }
    }

    return decodeLEB128(&tmp);
}

test "decoding by LEB128" {
    // 0x07以降はデコードされない
    var target = [_]u8{ 0xea, 0x09, 0x07, 0x69 };
    const decoded_number = decodeLEB128(&target);
    try std.testing.expect(decoded_number == 1258);
}
test "decoding by sLEB128" {
    // 0x07以降はデコードされない
    var target = [_]u8{ 0x80, 0x80, 0x80, 0x80, 0x08 };
    const decoded_number = decodesLEB128(&target);
    std.log.warn("\nnum:{}\n", .{decoded_number});
    try std.testing.expect(decoded_number == 2147483648);
}

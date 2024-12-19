//! コード実行に使用するスタックの定義
const STACK_SIZE = 1024;

const CurrentTopStack = enum {
    f64,
    f32,
    i64,
    i32,
};

// 4つの数値型のスタックを持ち、これらを操作するインターフェイスを提供する
// pop,pushするときは対象の型を必要とする
pub const Stack = struct {
    const f64stack = @constCast(&(GeneralStack(f64)));
    const f32stack = @constCast(&(GeneralStack(f32)));
    const i64stack = @constCast(&(GeneralStack(i64)));
    const i32stack = @constCast(&(GeneralStack(i32)));
    var top: CurrentTopStack = undefined;

    pub fn init() *Stack {
        var stack = Stack{};
        return @constCast(&stack);
    }

    pub fn push(self: *Stack, comptime T: type, value: T) void {
        _ = self;

        switch (T) {
            f64 => {
                f64stack.push(value);
                top = .f64;
            },
            f32 => {
                f32stack.push(value);
                top = .f32;
            },
            i64 => {
                i64stack.push(value);
                top = .i64;
            },
            i32 => {
                i32stack.push(value);
                top = .i32;
            },
            else => unreachable,
        }
    }

    pub fn pop(self: *Stack, comptime T: type) T {
        _ = self;
        const value = switch (T) {
            f64 => f64stack.pop(),
            f32 => f32stack.pop(),
            i64 => i64stack.pop(),
            u64 => i32stack.pop(),
            void => {
                // drop()命令等どのような型の値をpopさせるかわからないときはVoidを指定する
                // drop()命令は取り出す値を積んだ直後に呼ばれると想定しているため,最も新しく積まれた値を返す
                switch (top) {
                    .f64 => @import("std").debug.print("pop value: {}\n", .{f64stack.pop()}),
                    .f32 => @import("std").debug.print("pop value: {}\n", .{f32stack.pop()}),
                    .i64 => @import("std").debug.print("pop value: {}\n", .{i64stack.pop()}),
                    .i32 => @import("std").debug.print("pop value: {}\n", .{i32stack.pop()}),
                }
                return;
            },
            else => unreachable,
        };
        return value;
    }
};

fn GeneralStack(comptime T: type) type {
    return struct {
        const Self = @This();
        var stack: [STACK_SIZE]T = undefined;
        var top: usize = 0;

        pub fn push(value: T) void {
            top += 1;
            stack[top] = value;
        }
        pub fn pop() T {
            const value = stack[top];
            top -= 1;
            return value;
        }
    };
}

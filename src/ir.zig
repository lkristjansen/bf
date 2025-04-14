const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Type = enum {
    add,
    sub,
    shift_left,
    shift_right,
    write,
    read,
    jump_if_zero,
    jump_if_not_zero,
};

pub const Ir = union(Type) {
    add: u8,
    sub: u8,
    shift_left: u8,
    shift_right: u8,
    write: u8,
    read: u8,
    jump_if_zero: u64,
    jump_if_not_zero: u64,
};

pub const IrError = error{
    OutOfMemory,
    UnMatchedOpenBrace,
};

pub fn buildIr(allocator: Allocator, text: []const u8) IrError![]const Ir {
    var ir = ArrayList(Ir).init(allocator);
    errdefer ir.deinit();

    var stack = ArrayList(u64).init(allocator);
    defer stack.deinit();

    var scanner = Scanner.init(text);
    var index: u64 = 0;
    while (scanner.next()) |ch| : (index += 1) {
        switch (ch) {
            .add,
            .sub,
            .shift_left,
            .shift_right,
            .write,
            .read,
            => {
                var count: u8 = 1;
                while (scanner.peek() == ch) {
                    count += 1;
                    _ = scanner.next();
                }

                const op = switch (ch) {
                    .add => Ir{ .add = count },
                    .sub => Ir{ .sub = count },
                    .shift_left => Ir{ .shift_left = count },
                    .shift_right => Ir{ .shift_right = count },
                    .write => Ir{ .write = count },
                    .read => Ir{ .read = count },
                    else => unreachable,
                };

                try ir.append(op);
            },
            .jump_if_zero => {
                try stack.append(index);
                try ir.append(Ir{ .jump_if_zero = 0 });
            },
            .jump_if_not_zero => {
                if (stack.pop()) |openBraceIndex| {
                    ir.items[openBraceIndex].jump_if_zero = index + 1;
                    try ir.append(.{ .jump_if_not_zero = openBraceIndex + 1 });
                } else {
                    return IrError.UnMatchedOpenBrace;
                }
            },
        }
    }

    return try ir.toOwnedSlice();
}

const Scanner = struct {
    text: []const u8,
    index: usize,

    fn init(text: []const u8) Scanner {
        return Scanner{
            .text = text,
            .index = 0,
        };
    }

    fn next(self: *Scanner) ?Type {
        if (self.peek()) |token| {
            self.index += 1;
            return token;
        }
        return null;
    }

    fn peek(self: *Scanner) ?Type {
        const len = self.text.len;

        while (self.index < len) {
            const ch = self.text[self.index];

            switch (ch) {
                '+' => return .add,
                '-' => return .sub,
                '<' => return .shift_left,
                '>' => return .shift_right,
                '.' => return .write,
                ',' => return .read,
                '[' => return .jump_if_zero,
                ']' => return .jump_if_not_zero,
                else => {
                    self.index += 1;
                },
            }
        }

        return null;
    }
};

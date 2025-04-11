const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Ir = union(enum) {
    add: u64,
    sub: u64,
    out: u64,

    fn fromChar(ch: u8, value: u64) ?Ir {
        return switch (ch) {
            '+' => Ir{ .add = value },
            '-' => Ir{ .sub = value },
            '.' => Ir{ .out = value },
            else => null,
        };
    }
};

const expectEqual = std.testing.expectEqual;
const testAllocator = std.testing.allocator;

test "Ir.fromChar" {
    try expectEqual(null, Ir.fromChar('æ', 0));
    try expectEqual(Ir{ .add = 1001 }, Ir.fromChar('+', 1001));
    try expectEqual(Ir{ .out = 2 }, Ir.fromChar('.', 2));
}

pub const IrError = error{
    OutOfMemory,
};

pub fn buildIr(allocator: Allocator, text: []const u8) IrError![]const Ir {
    var ir = ArrayList(Ir).init(allocator);
    errdefer ir.deinit();

    var scanner = Scanner.init(text);

    while (scanner.next()) |ch| {
        switch (ch) {
            '+', '-', '.' => {
                var count: u64 = 1;
                while (scanner.peek() == ch) {
                    count += 1;
                    _ = scanner.next();
                }

                if (Ir.fromChar(ch, count)) |irToken| {
                    try ir.append(irToken);
                } else {
                    unreachable;
                }
            },
            else => unreachable,
        }
    }

    return try ir.toOwnedSlice();
}

test "buildIr() empty input" {
    const ir = try buildIr(testAllocator, "");
    try expectEqual(0, ir.len);
}

test "buildIr() ++++ .." {
    const ir = try buildIr(testAllocator, "  ++++ ----- .   .");
    defer testAllocator.free(ir);

    try expectEqual(3, ir.len);
    try expectEqual(Ir{ .add = 4 }, ir[0]);
    try expectEqual(Ir{ .sub = 5 }, ir[1]);
    try expectEqual(Ir{ .out = 2 }, ir[2]);
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

    fn next(self: *Scanner) ?u8 {
        const len = self.text.len;

        while (self.index < len) {
            const ch = self.text[self.index];

            switch (ch) {
                '+', '-', '.' => {
                    self.index += 1;
                    return ch;
                },
                else => {
                    self.index += 1;
                },
            }
        }

        return null;
    }

    fn peek(self: *Scanner) ?u8 {
        const len = self.text.len;

        while (self.index < len) {
            const ch = self.text[self.index];

            switch (ch) {
                '+', '-', '.' => {
                    return ch;
                },
                else => {
                    self.index += 1;
                },
            }
        }

        return null;
    }
};

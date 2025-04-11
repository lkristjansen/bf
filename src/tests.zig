const std = @import("std");

pub const _ = @import("ir.zig");

test {
    std.testing.refAllDecls(@This());
}

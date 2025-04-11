const std = @import("std");
const Ir = @import("ir.zig").Ir;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const CompilerError = error{
    OutOfMemory,
};

pub const MachineCode = struct {
    bytes: []u8,
    bss: []const u64,
};

pub fn compile(allocator: Allocator, ir: []const Ir) CompilerError!MachineCode {
    var codeBuffer = ArrayList(u8).init(allocator);
    errdefer codeBuffer.deinit();

    var bssBuffer = ArrayList(u64).init(allocator);
    errdefer bssBuffer.deinit();

    const writer = codeBuffer.writer();
    try movRegImm64(0, .rsi, writer);
    try bssBuffer.append(2);

    for (ir) |instr| {
        switch (instr) {
            .add => |imm8| {
                try addRegImm8(@as(u8, @intCast(imm8)), .rsi, writer);
            },
            .sub => |imm8| {
                try subRsiImm8(@as(u8, @intCast(imm8)), writer);
            },
            .out => |N| {
                try movRegImm64(1, .rax, writer);
                try movRegImm64(1, .rdi, writer);
                try movRegImm64(1, .rdx, writer);

                for (0..N) |_| {
                    try syscall(writer);
                }
            },
        }
    }

    try movRegImm64(0, .rdi, writer);
    try movRegImm64(60, .rax, writer);
    try syscall(writer);

    const bytes = try codeBuffer.toOwnedSlice();
    errdefer allocator.free(bytes);

    const bss = try bssBuffer.toOwnedSlice();

    return MachineCode{ .bytes = bytes, .bss = bss };
}

const Reg = enum(u8) {
    rax = 0,
    rcx = 1,
    rdx = 2,
    rbx = 3,
    rsp = 4,
    rbp = 5,
    rsi = 6,
    rdi = 7,
};

const Little = std.builtin.Endian.little;

fn movRegImm64(imm64: u64, reg: Reg, writer: anytype) CompilerError!void {
    try writer.writeAll(&[_]u8{ 0x48, 0xb8 + @intFromEnum(reg) });
    try writer.writeInt(u64, imm64, Little);
}

fn addRegImm8(imm8: u8, reg: Reg, writer: anytype) CompilerError!void {
    try writer.writeAll(&[_]u8{ 0x80, @intFromEnum(reg), imm8 });
}

fn subRsiImm8(imm8: u8, writer: anytype) CompilerError!void {
    try writer.writeAll(&[_]u8{ 0x80, 0x2e, imm8 });
}

fn syscall(writer: anytype) CompilerError!void {
    try writer.writeAll(&[_]u8{ 0xf, 0x5 });
}

const std = @import("std");

const elf = @import("elf.zig");
const ir = @import("ir.zig");
const compiler = @import("compiler.zig");

pub fn main() !void {
    var args = std.process.args();

    _ = args.next(); // eat program name

    if (args.next()) |inFileName| {
        const allocator = std.heap.page_allocator;
        const infile = try std.fs.cwd().openFile(inFileName, .{});
        defer infile.close();
        const text = try infile.reader().readAllAlloc(allocator, 0x1000);

        const irCode = try ir.buildIr(allocator, text);
        const code = try compiler.compile(allocator, irCode);

        const outfile = try std.fs.cwd().createFile("a.out", .{ .mode = 0o755 });
        try outfile.chmod(0o755);

        defer outfile.close();

        try elf.write(code, outfile.writer());
    } else {
        std.debug.print("missing argument inputfile", .{});
    }
}

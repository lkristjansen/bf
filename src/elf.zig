const std = @import("std");
const MachineCode = @import("compiler.zig").MachineCode;

const ElfMag0 = 0x7f;
const ElfMag1 = 'E';
const ElfMag2 = 'L';
const ElfMag3 = 'F';

const Ei_Class = enum(u8) { none = 0, class32 = 1, class64 = 2 };

const Ei_Data = enum(u8) { none = 0, lsb = 1, msb = 2 };

const Ei_Version = enum(u8) { none = 0, current = 1 };

const Ei_OsAbi = enum(u8) { none = 0, sys_v = 1 };

const Elf64_Ident = extern struct {
    mag0: u8,
    mag1: u8,
    mag2: u8,
    mag3: u8,
    class: Ei_Class,
    data: Ei_Data,
    version: Ei_Version,
    os_abi: Ei_OsAbi,
    abi_version: u8,
    pad0: u8,
    pad1: u8,
    pad2: u8,
    pad3: u8,
    pad4: u8,
    pad5: u8,
    pad6: u8,

    fn init() Elf64_Ident {
        return Elf64_Ident{
            .mag0 = ElfMag0,
            .mag1 = ElfMag1,
            .mag2 = ElfMag2,
            .mag3 = ElfMag3,
            .class = .class64,
            .data = .lsb,
            .version = .current,
            .os_abi = .none,
            .abi_version = 0,
            .pad0 = 0,
            .pad1 = 0,
            .pad2 = 0,
            .pad3 = 0,
            .pad4 = 0,
            .pad5 = 0,
            .pad6 = 0,
        };
    }
};

const FileType = enum(u16) {
    none = 0,
    rel = 1,
    exec = 2,
    dyn = 3,
    core = 4,
};

const Machine = enum(u16) {
    none = 0,
    x86_64 = 0x3e,
};

const Version = enum(u32) {
    none = 0,
    current = 1,
};

const Elf64_Ehdr = extern struct {
    e_ident: Elf64_Ident,
    e_type: FileType,
    e_machine: Machine,
    e_version: Version,
    e_entry: u64,
    e_phoff: u64,
    e_shoff: u64,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
};

const Type = enum(u32) {
    load = 1,
};

const PT_EXEC = 1;
const PT_WRITE = 2;
const PT_READ = 4;

const Elf64_Phdr = extern struct {
    p_type: Type,
    p_flags: u32,
    p_offset: u64,
    p_vaddr: u64,
    p_paddr: u64,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,
};

pub fn write(code: MachineCode, writer: anytype) !void {
    const baseVirtualAddr: u64 = 0x400000;
    const pageSize = 0x1000;
    const codeOffset = 0x1000;
    const codeVirtualAddr = baseVirtualAddr + codeOffset;
    const bssVirtualAddr = codeVirtualAddr + 0x100;
    const bssSize = 1024 * 1024;

    var codeBlock = code.bytes;
    std.mem.writeInt(u64, codeBlock[2..10], bssVirtualAddr, std.builtin.Endian.little);

    const ehdr = Elf64_Ehdr{
        .e_ident = Elf64_Ident.init(),
        .e_type = .exec,
        .e_machine = .x86_64,
        .e_version = .current,
        .e_entry = codeVirtualAddr,
        .e_phoff = @sizeOf(Elf64_Ehdr),
        .e_ehsize = @sizeOf(Elf64_Ehdr),
        .e_phentsize = @sizeOf(Elf64_Phdr),
        .e_phnum = 1,
        .e_shentsize = 0,
        .e_shoff = 0,
        .e_flags = 0,
        .e_shnum = 0,
        .e_shstrndx = 0,
    };

    const phdr = Elf64_Phdr{
        .p_type = .load,
        .p_flags = PT_READ | PT_WRITE | PT_EXEC,
        .p_offset = codeOffset,
        .p_vaddr = codeVirtualAddr,
        .p_paddr = codeVirtualAddr,
        .p_filesz = codeBlock.len,
        .p_memsz = codeBlock.len + bssSize + 0x100,
        .p_align = pageSize,
    };

    try writer.writeStruct(ehdr);
    try writer.writeStruct(phdr);
    try writer.writeByteNTimes(0, codeOffset - @sizeOf(Elf64_Ehdr) - @sizeOf(Elf64_Phdr));
    try writer.writeAll(codeBlock);
}

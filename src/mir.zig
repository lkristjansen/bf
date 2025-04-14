pub const Machine = enum {
    x86_64,
    x86_32,
};

pub const SystemAbi = enum {
    sys_v,
};

pub const SectionType = enum {
    text,
    bss,
};

pub const Register = enum(u8) {
    rax,
    rcx,
    rdx,
    rbx,
};

pub const Operation = enum {
    mov_imm32_reg,
    mov_imm64_reg,
    add_imm8,
    sub_imm8,
    syscall,
};

pub const Instruction = union(Operation) {};

pub const Bss = struct {
    size: usize,
};

pub const Text = struct {
    bytes: []Instruction,
};

pub const Section = union(SectionType) {
    text: Text,
    bss: Bss,
};

pub const Chunk = struct {
    machine: Machine,
    system_abi: SystemAbi,
    sections: []Section,
};

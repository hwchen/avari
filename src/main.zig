//! Consume an ELF binary, produces a report.
//!
//! Usage:
//! ```shell
//! avari <filepath>

const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.skip();
    const binary_path = args.next() orelse return error.MissingBinaryPathArg;
    const f = try std.fs.cwd().openFile(binary_path, .{});
    const rdr = f.reader();

    const header = rdr.readStruct(Elf32_Ehdr) catch return error.InvalidElfHeader;

    // Write report
    {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        var x: usize = 0;
        while (x < EI_NIDENT) : (x += 1) {
            try stdout.print("{:03}: {c}\n", .{ header.e_ident[x], header.e_ident[x] });
        }

        try bw.flush(); // don't forget to flush!
    }
}

const Elf32_Ehdr = extern struct {
    e_ident: [EI_NIDENT]u8,
    e_type: Elf32_Half,
    e_machine: Elf32_Half,
    e_version: Elf32_Word,
    e_entry: Elf32_Addr,
    e_phoff: Elf32_Off,
    e_shoff: Elf32_Off,
    e_flags: Elf32_Word,
    e_ehsize: Elf32_Half,
    e_phentsize: Elf32_Half,
    e_ph_num: Elf32_Half,
    e_shentsize: Elf32_Half,
    e_shnum: Elf32_Half,
    e_shstrndx: Elf32_Half,
};

const EI_NIDENT: usize = 16;

// Data representation with expected C alignment
const Elf32_Addr = u32;
const Elf32_Half = u16;
const Elf32_Off = u32;
const Elf32_Sword = i32;
const Elf32_Word = u32;
const Elf32_Byte = u8;

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

        {
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                try stdout.print("{:03}: {c}\n", .{ header.e_ident.elf_mag[i], header.e_ident.elf_mag[i] });
            }
        }

        try stdout.print("{:03}: {s}\n", .{ @enumToInt(header.e_ident.file_class), @tagName(header.e_ident.file_class) });

        {
            var i: usize = 0;
            while (i < EI_NIDENT - 5) : (i += 1) {
                try stdout.print("{:03}: {c}\n", .{ header.e_ident.other[i], header.e_ident.other[i] });
            }
        }

        try bw.flush(); // don't forget to flush!
    }
}

// Data type representation with expected C alignment
const Elf32_Addr = u32;
const Elf32_Half = u16;
const Elf32_Off = u32;
const Elf32_Sword = i32;
const Elf32_Word = u32;
const Elf32_Byte = u8;

/// Elf Header
const Elf32_Ehdr = extern struct {
    e_ident: EIdent,
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

// e_ident ====================================
// [0][1][2][3][4][5][6][7][8][9][A][B][C][D][E][F]

const EI_NIDENT: usize = 16;

const EIdent = extern struct {
    // [0-3]; magic value

    elf_mag: [4]u8,

    /// [4]; EI_Class
    file_class: FileClass,

    other: [EI_NIDENT - 5]u8,
};

const FileClass = enum(u8) {
    elf_class_none, // 0
    elf_class_32, // 1
    elf_class_64, // 2
};

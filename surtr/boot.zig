const std = @import("std");
const uefi = std.os.uefi;

fn _main() uefi.Error!void {
    const con_out = uefi.system_table.con_out orelse return error.Aborted;
    try con_out.clearScreen();

    for ("Hello, world!\n") |b| {
        if (try con_out.outputString(&[_:0]u16{b})) {} else {
            return error.Aborted;
        }
    }
}

pub fn main() uefi.Status {
    _main() catch |err| {
        switch (err) {
            error.Unexpected => {},
            else => {
                const status_err: uefi.Status.Error = @errorCast(err);
                return uefi.Status.fromError(status_err);
            },
        }
    };

    while (true) asm volatile ("hlt");

    return .success;
}

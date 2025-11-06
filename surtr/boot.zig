const std = @import("std");
const uefi = std.os.uefi;

const blog = @import("log.zig");
const log = std.log.scoped(.surtr);
//  Override the default log options
pub const std_options = blog.default_log_options;

fn _main() uefi.Error!void {
    const con_out = uefi.system_table.con_out orelse return error.Aborted;
    try con_out.clearScreen();

    blog.init(con_out);
    log.info("Initialized bootloader log.", .{});
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

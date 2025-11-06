const std = @import("std");
const stdlog = std.log;
const uefi = std.os.uefi;
const Sto = uefi.protocol.SimpleTextOutput;
const option = @import("option");

pub const default_log_options = std.Options{
    .log_level = switch (option.log_level) { // m
        .debug => .debug,
        .info => .info,
        .warn => .warn,
        .err => .err,
    },
    .logFn = logFn,
};

var con_out: *Sto = undefined;

/// Initialize bootloader log.
pub fn init(out: *Sto) void {
    con_out = out;
}

const LogError = error{};
fn writerFn(_: void, bytes: []const u8) LogError!usize {
    for (bytes) |b| {
        // EFI uses UCS-2 encoding.
        if (con_out.outputString(&[_:0]u16{b}) catch {
            unreachable;
        }) {} else {
            unreachable;
        }
    }
    return bytes.len;
}

const Writer = std.io.GenericWriter(
    void,
    LogError,
    writerFn,
);

fn logFn(
    comptime level: stdlog.Level,
    comptime scope: @Type(.enum_literal),
    comptime fmt: []const u8,
    args: anytype,
) void {
    const level_str = comptime switch (level) {
        .debug => "[DEBUG]",
        .info => "[INFO ]",
        .warn => "[WARN ]",
        .err => "[ERROR]",
    };

    const scope_str = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    std.fmt.format(
        Writer{
            .context = {},
        },
        level_str ++ scope_str ++ fmt ++ "\r\n",
        args,
    ) catch unreachable;
}
